import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";
  late final String _apiKey;

  final List<Map<String, String>> _chatHistory = [];
  // هاد هو الكتالوج اللي بيشرح للـ AI شو بيقدر يعمل، وكيف يبعث الداتا بالضبط
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
              // هون الحل السحري تبعك: الموديل مستحيل يبعث إشي برا هاي اللستة
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
                "Endocrinology"
              ]
            },
            "sort_by": {
              "type": "string",
              "description":
                  "How to sort the doctors. Use 'nearest' if the user asks for the closest doctor. Use 'rating' for top rated.",
              "enum": ["rating", "nearest", "none"]
            }
          },
          "required": ["specialty"]
        }
      }
    }
    // لبعدين رح نضيف هون أدوات المواعيد (get_availability, book, cancel)
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
          "temperature": 0.5
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String aiText = data['choices'][0]['message']['content'];

        _chatHistory.add({"role": "assistant", "content": aiText});

        return aiText;
      } else {
        _chatHistory.removeLast();
        return "Server error: ${response.statusCode}\nDetails: ${response.body}";
      }
    } catch (e) {
      _chatHistory.removeLast();
      return "Connection issue: $e";
    }
  }
}
