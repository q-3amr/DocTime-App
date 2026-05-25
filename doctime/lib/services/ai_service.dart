import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";
  late final String _apiKey;

  final List<Map<String, String>> _chatHistory = [];

  AiService() {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('API Key for Groq is missing in .env file!');
    }
    _apiKey = key.trim();

_chatHistory.add({
      "role": "system",
      "content": """You are a medical triage assistant for the DocTime app.
You MUST respond ONLY in valid JSON format. No markdown, no extra text.
Your JSON response must strictly follow this structure:
{
  "status": "asking" or "finished",
  "message": "your next short question OR your final advice",
  "urgency": "none", "green", "yellow", or "red",
  "specialty": "none" or one of [General Medicine, Dentistry, Cardiology, Psychiatry, Nutrition, Urology, Dermatology, Gynecology & Obstetrics, Orthopedics, Pediatrics, Internal Medicine, Ophthalmology, Neurology, Gastroenterology, ENT, Pulmonology, Endocrinology]
}

RULES:
1. Ask a maximum of 5 questions, one by one. While asking, set "status": "asking", "urgency": "none", "specialty": "none", and put your question in "message".
2. If symptoms are mild (e.g., simple cold, mild headache) and you reached a conclusion, set "status": "finished", "urgency": "green", "specialty": "none". Put home care advice in "message".
3. If symptoms require a doctor, set "status": "finished", "urgency": "yellow", and provide the EXACT specialty name.
4. If symptoms indicate a severe emergency (e.g., chest pain, severe bleeding), IMMEDIATELY set "status": "finished", "urgency": "red", "specialty": "none". Tell the user to go to the ER in "message".
5. Never output anything outside the JSON brackets."""
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
