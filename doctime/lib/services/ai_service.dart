import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'database_service.dart';
import 'package:geolocator/geolocator.dart';

class AiService {
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";
  late final String _apiKey;
  final DatabaseService _db = DatabaseService();
  final List<Map<String, dynamic>> _chatHistory = [];
  final List<Map<String, dynamic>> _tools = [
    {
      "type": "function",
      "function": {
        "name": "search_doctors",
        "description":
            "Search for doctors in the database based on a specific specialty. Use this when the user asks to find a doctor, asks about a specialty, or needs the nearest doctor.",
        "parameters": {
          "type": "object",
          "properties": {
            "specialty": {
              "type": "string",
              "description": "The exact medical specialty required.",
              "enum": [
                "General Medicine",
                "Dentistry",
                "Cardiology",
                "Psychiatry",
                "Nutrition",
                "Urology",
                "Dermatology",
                "Gynecology & Obstetrics",
                "Orthopedics",
                "Pediatrics",
                "Internal Medicine",
                "Ophthalmology",
                "Neurology",
                "Gastroenterology",
                "ENT",
                "Pulmonology",
                "Endocrinology",
                "Otolaryngology"
              ]
            },
            "sort_by": {
              "type": "string",
              "description":
                  "How to sort the doctors. Use 'nearest' if the user asks for the closest doctor. Use 'rating' for top rated.",
              "enum": ["rating", "nearest", "none"]
            }
          },
          "required": ["specialty", "sort_by"]
        }
      }
    }
  ];
  AiService() {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('API Key for Groq is missing in .env file!');
    }
    _apiKey = key.trim();

    _chatHistory.add({
      "role": "system",
      "content":
          """You are an advanced medical triage and booking AI Agent for the DocTime app.
You have access to tools to search for doctors, check schedules, and manage appointments.

IMPORTANT RULE: When you are NOT calling a tool (e.g., when asking triage questions, giving advice, or chatting with the user), you MUST respond ONLY in valid JSON format exactly like this:
{
  "status": "asking" or "finished",
  "message": "your text response to the user",
  "urgency": "none", "green", "yellow", or "red",
  "specialty": "none" or the medical specialty (e.g., General Medicine, Cardiology, etc.)
}

RULES:
1. If the user asks about doctors, finding a doctor, booking, or appointments, DO NOT guess. USE THE APPROPRIATE TOOL.
2. If you are doing medical triage, ask a maximum of 5 questions one by one.
3. Never output any markdown or text outside the JSON structure when talking to the user."""
    });
  }

  Future<String> getAiResponse(String userMessage) async {
    _chatHistory.add({"role": "user", "content": userMessage.trim()});
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": _chatHistory,
          "temperature": 0.5,
          "tools": _tools,
          "tool_choice": "auto"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseMessage = data['choices'][0]['message'];

        if (responseMessage['tool_calls'] != null) {
          final toolCalls = responseMessage['tool_calls'];
          final toolCall = toolCalls[0];
          final toolCallId = toolCall['id'];
          final toolName = toolCall['function']['name'];

          final toolArgs = jsonDecode(toolCall['function']['arguments']);

          _chatHistory.add(
              {"role": "assistant", "content": null, "tool_calls": toolCalls});

          String toolResultString = "";

          if (toolName == "search_doctors") {
            final String specialty = toolArgs['specialty'];
            final String sortBy =
                toolArgs['sort_by'] ?? toolArgs['sortBy'] ?? "none";

            if (sortBy == "nearest") {
              try {
                // بنشيك إذا خدمة الـ GPS شغالة أصلاً بالتلفون
                bool serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  toolResultString =
                      '{"error": "Location service is off. Ask the user to turn on GPS."}';
                } else {
                  // بنشيك الصلاحيات وبنطلبها إذا مش موجودة
                  LocationPermission permission =
                      await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                  }

                  if (permission == LocationPermission.denied ||
                      permission == LocationPermission.deniedForever) {
                    toolResultString =
                        '{"error": "Location permission denied. Tell the user you cannot find the nearest doctor without it."}';
                  } else {
                    // إذا كل أمور الـ GPS تمام، بنسحب اللوكيشن وبنبعثه لدالة الفايربيز
                    Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high);
                    toolResultString = await _db.searchDoctorsForAi(
                        specialty, sortBy,
                        userLat: position.latitude,
                        userLng: position.longitude);
                  }
                }
              } catch (e) {
                toolResultString = '{"error": "Failed to get location: $e"}';
              }
            } else {
              toolResultString =
                  await _db.searchDoctorsForAi(specialty, sortBy);
            }
          } else {
            toolResultString =
                '{"error": "Tool $toolName not found or not implemented yet."}';
          }

          _chatHistory.add({
            "role": "tool",
            "tool_call_id": toolCallId,
            "name": toolName,
            "content": toolResultString
          });

          final secondResponse = await http.post(
            Uri.parse(_apiUrl),
            headers: {
              "Authorization": "Bearer $_apiKey",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "model": "llama-3.3-70b-versatile",
              "messages": _chatHistory,
              "temperature": 0.5
            }),
          );

          if (secondResponse.statusCode == 200) {
            final secondData = jsonDecode(secondResponse.body);
            final String finalAiText =
                secondData['choices'][0]['message']['content'];

            _chatHistory.add({"role": "assistant", "content": finalAiText});
            return finalAiText;
          } else {
            _chatHistory.removeRange(
                _chatHistory.length - 2, _chatHistory.length);
            return '{"status": "asking", "message": "Server error in second round: ${secondResponse.statusCode}", "urgency": "none", "specialty": "none"}';
          }
        } else {
          final String aiText = responseMessage['content'];
          _chatHistory.add({"role": "assistant", "content": aiText});
          return aiText;
        }
      } else {
        _chatHistory.removeLast();
        return '{"status": "asking", "message": "Server error: ${response.statusCode}", "urgency": "none", "specialty": "none"}';
      }
    } catch (e) {
      _chatHistory.removeLast();
      return '{"status": "asking", "message": "Connection issue: $e", "urgency": "none", "specialty": "none"}';
    }
  }
}
