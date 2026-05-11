import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";
  late final String _apiKey;

  AiService() {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('API Key for Groq is missing in .env file!');
    }
    _apiKey = key.trim();
  }

  Future<String> getAiResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          // استخدمنا أسرع موديل عند جروق
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              // هاد هو الـ System Prompt اللي ببرمج مخ البوت
              "role": "system",
              "content":
                  "You are a strict, concise medical triage assistant for the DocTime app. Your goal is to gather information about the patient's symptoms. ONLY ask one short, direct question at a time to narrow down the condition. DO NOT provide a final diagnosis. DO NOT write lists or long paragraphs. Keep your response under 3 sentences."
            },
            {"role": "user", "content": userMessage.trim()}
          ],
          "temperature": 0.5 // عشان نقلل الهلوسة ونخليه جدي
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Server error: ${response.statusCode}\nDetails: ${response.body}";
      }
    } catch (e) {
      return "Connection issue: $e";
    }
  }
}
