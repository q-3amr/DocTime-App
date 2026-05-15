import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";
  late final String _apiKey;
  // مصفوفة الذاكرة اللي رح تكبر مع كل رسالة
  final List<Map<String, String>> _chatHistory = [];

  AiService() {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('API Key for Groq is missing in .env file!');
    }
    _apiKey = key.trim();
    // 1. أول مسج "خلق البوت"
    _chatHistory.add({
      "role": "system",
      "content":
          """You are a strict medical triage assistant for the DocTime app. Your goal is to recommend the correct medical specialty based on symptoms.
RULES:
1. Ask ONLY ONE short, direct question at a time to narrow down the condition.
2. DO NOT provide a medical diagnosis or prescribe medication.
3. You MUST STOP asking questions after a maximum of 5 questions.
4. Once you have enough information (or reached the 5-question limit), you MUST recommend ONE specialty EXACTLY as it appears in this list: [General Medicine, Dentistry, Cardiology, Psychiatry, Nutrition, Urology, Dermatology, Gynecology & Obstetrics, Orthopedics, Pediatrics, Internal Medicine, Ophthalmology, Neurology, Gastroenterology, ENT, Pulmonology, Endocrinology, Otolaryngology].
5. Your final sentence MUST be exactly: 'I recommend you book an appointment with a [Specialty]'. Do not add any extra words to the specialty name.
6. If the user asks non-medical questions, reply ONLY with: 'I am a medical assistant. Please describe your symptoms.' and repeat your last question."""
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
          // استخدمنا أسرع موديل عند جروق
          "model": "llama-3.3-70b-versatile",
          "messages": _chatHistory,
          "temperature": 0.5 // عشان نقلل الهلوسة ونخليه جدي
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String aiText = data['choices'][0]['message']['content'];

        _chatHistory.add({"role": "assistant", "content": aiText});

        return aiText; // عدل سطر الـ return القديم ليصير هيك
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
