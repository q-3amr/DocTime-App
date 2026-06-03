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
    },
    {
      "type": "function",
      "function": {
        "name": "get_doctor_availability",
        "description":
            "Check the available time slots for a specific doctor on a specific date. Use this ONLY after the user has selected a doctor and wants to know when they are available to book.",
        "parameters": {
          "type": "object",
          "properties": {
            "doctor_id": {
              "type": "string",
              "description":
                  "The exact ID of the doctor (obtained from the search_doctors tool)."
            },
            "date": {
              "type": "string",
              "description":
                  "The date to check, formatted exactly as YYYY-MM-DD (e.g., 2026-05-29)."
            }
          },
          "required": ["doctor_id", "date"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "book_appointment",
        "description":
            "Book an appointment with a doctor. Use this ONLY after you have successfully retrieved the doctor's available slots using get_doctor_availability, and the user has explicitly chosen a specific time slot from that list.",
        "parameters": {
          "type": "object",
          "properties": {
            "doctor_id": {
              "type": "string",
              "description": "The exact ID of the doctor to book with."
            },
            "date": {
              "type": "string",
              "description": "The chosen date, formatted EXACTLY as YYYY-MM-DD."
            },
            "time": {
              "type": "string",
              "description":
                  "The exact time slot the user picked (e.g., '10:00 PM'). It MUST be one of the available slots you previously showed them."
            }
          },
          "required": ["doctor_id", "date", "time"]
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
    String todayDate = DateTime.now().toString().split(' ')[0];
    _chatHistory.add({
      "role": "system",
      "content":
          """You are an advanced medical triage and booking AI Agent for the CareFlow app.
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
2. DYNAMIC TRIAGE LIMIT: Ask a maximum of 3 targeted questions one by one to determine the medical specialty. CRITICAL: If the patient's initial or subsequent inputs already provide enough clinical clues to confidently determine the specialty, STOP asking questions immediately and proceed directly to the triage-to-booking flow. Do not force unnecessary questions if the specialty is clear.
3. Never output any markdown or text outside the JSON structure when talking to the user.
4. CRITICAL GPS RULE: Differentiate between the user's GPS and the doctors' locations. If the tool returns an error specifically saying the USER'S location/GPS is off or denied, tell the user to turn it on. BUT, if the tool says that "no doctors have registered their locations", DO NOT blame the user's GPS. Simply tell the user: "There are no doctors with registered locations for this specialty near you."
5. CRITICAL: When using the search_doctors tool, YOU MUST READ THE EXACT "distance_in_km" provided in the JSON response. NEVER assume or change the distance to 0.0. Even if the distance is huge (e.g., 11000 km), REPORT IT EXACTLY as received. DO NOT hallucinate doctor names or distances.
6. CRITICAL: When responding to the user after using a tool, formulate a natural, human-like sentence in the "message" field. DO NOT output code, technical logs, or raw JSON inside the "message" string. Just speak naturally.
7. CRITICAL DATE RULE: Today's exact date is $todayDate. If the user mentions ANY time format (e.g., "today", "tomorrow", "next Sunday", "1 June", "1/6", "1-6"), DO NOT ask them for the date. You are an AI, figure it out! You MUST silently interpret their input based on the current year and month, convert it EXACTLY to YYYY-MM-DD format, and immediately call the get_doctor_availability tool. Example: If today is 2026-05-30 and the user says "1 june" or "1/6", you must automatically pass "2026-06-01" to the tool.
8. ONLY ask the user "For which date..." if they ask for availability WITHOUT mentioning ANY timeframe at all.
9. CRITICAL UI RULE: ALWAYS set "status": "asking" while using ANY tool (including search_doctors, get_doctor_availability, and booking appointments) or when providing information. NEVER set "status": "finished" just because you answered a question or completed a tool call. You MUST keep the conversation open so the user can continue the flow. ONLY set "status": "finished" if the patient explicitly ends the conversation (e.g., saying "I am done", "thank you", "bye", "that is all").
10. CRITICAL RESPONSE RULE: When answering a query about a doctor (e.g., nearest or top-rated), KEEP IT BRIEF. ONLY mention the doctor's name, specialty, and the primary metric requested (e.g., rating or distance). DO NOT output the number of reviews or distance if it is 0.0. NEVER say "located 0.0 km away". If distance is 0.0, assume they do not have a location set and do not mention distance at all.
11. CRITICAL TRIAGE-TO-BOOKING FLOW: When you finish asking the medical triage questions (maximum 5) and determine the urgency (Red, Blue, etc.) AND that the patient needs a doctor:
- DO NOT end the conversation.
- DO NOT tell the patient to click any buttons.
- You MUST tell them the specific medical specialty they need (e.g., General Medicine, Dentistry, Cardiology).
- Then, IMMEDIATELY ask them naturally: "You need to see a [Specialty] doctor. Would you like me to find the best options for you here and book an appointment?"

12. IF THE PATIENT AGREES TO BOOK: 
- Ask them EXACTLY this: "Great! Do you prefer the nearest doctor, the top-rated one, or are you looking for a specific doctor by name?"
- Wait for their answer.
- Once they answer (e.g., "nearest"), IMMEDIATELY use the `search_doctors` tool with the correct `sort_by` parameter and the specialty you determined.
- After finding the doctor, naturally transition to checking availability using `get_doctor_availability`, and finally use `book_appointment`.

13. UI STATE LOCK: During this ENTIRE flow (Triage -> Search -> Availability -> Booking), you MUST keep "status": "asking". NEVER send "status": "finished" unless the patient explicitly says they don't want to book or ends the chat.
14. STRICT CONTEXT RETENTION: If the patient interrupts the triage flow with an off-topic question (e.g., asking for the date, time, weather, or general knowledge), you MUST execute a two-step pivot in a single response:
- First, answer their off-topic question directly and briefly in ONE short sentence.
- Second, in the exact same response, IMMEDIATELY pivot back to the medical triage by asking the next pending symptom question or repeating the last unanswered triage question.
- Example Response: "Tomorrow's date is 2026-06-04. Now, returning to your severe headache, have you noticed any sensitivity to bright lights or nausea?"
- NEVER drop the triage state or ask the user general open-ended questions like "Is there anything else you want to do on this date?" during an active triage."""
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
            String rawSort =
                (toolArgs['sort_by'] ?? toolArgs['sortBy'] ?? "none")
                    .toString()
                    .toLowerCase()
                    .trim();
            final String sortBy =
                rawSort.contains("near") ? "nearest" : rawSort;

            if (sortBy == "nearest") {
              try {
                bool serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  toolResultString =
                      '{"error": "Location service is off. You MUST explicitly ask the user to turn on their device GPS in order to find the nearest doctor."}';
                } else {
                  LocationPermission permission =
                      await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                  }

                  if (permission == LocationPermission.denied ||
                      permission == LocationPermission.deniedForever) {
                    toolResultString =
                        '{"error": "Location permission denied. You MUST tell the user that you cannot find the nearest doctor without GPS permissions."}';
                  } else {
                    Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high);
                    toolResultString = await _db.searchDoctorsForAi(
                        specialty, sortBy,
                        userLat: position.latitude,
                        userLng: position.longitude);
                  }
                }
              } catch (e) {
                toolResultString =
                    '{"error": "Failed to get location from the device: $e"}';
              }
            } else {
              toolResultString =
                  await _db.searchDoctorsForAi(specialty, sortBy);
            }
          } else if (toolName == "get_doctor_availability") {
            final String doctorId = toolArgs['doctor_id'];
            final String date = toolArgs['date'];

            try {
              toolResultString =
                  await _db.getDoctorAvailabilityForAi(doctorId, date);
            } catch (e) {
              toolResultString =
                  '{"error": "Failed to get availability from database: $e"}';
            }
          } else if (toolName == "book_appointment") {
            final String doctorId = toolArgs['doctor_id'];
            final String date = toolArgs['date'];
            final String time = toolArgs['time'];

            try {
              toolResultString =
                  await _db.bookAppointmentForAi(doctorId, date, time);
            } catch (e) {
              toolResultString =
                  '{"error": "Failed to execute booking tool: $e"}';
            }
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
