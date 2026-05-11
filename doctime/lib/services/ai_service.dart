import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  late final GenerativeModel _model;

  AiService() {
    // 1. بنسحب المفتاح من ملف الـ .env
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    // 2. حماية: إذا نسينا نحط المفتاح، التطبيق بضرب إيرور واضح بدل ما يضل معلق
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key is missing! Please check your .env file.');
    }

    // 3. تهيئة الموديل (استخدمنا gemini-1.5-flash لأنه سريع جداً ومناسب للـ Triage)
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  // 4. هاي الدالة اللي الشاشة تبعتك رح تناديها
  Future<String> getAiResponse(String userMessage) async {
    try {
      // بنغلف رسالة المريض بالشكل اللي بتفهمه جوجل
      final content = [Content.text(userMessage)];

      // بنبعث الطلب وبنستنى الرد
      final response = await _model.generateContent(content);

      // بنرجع النص، وإذا كان null بنرجع رسالة خطأ بديلة
      return response.text ??
          "Sorry, I couldn't process your request at the moment.";
    } catch (e) {
      // إذا فصل النت أو صار إيرور بالـ API، بنمسكه هون وما بنخلي التطبيق يكرش
      return "Connection issue: $e";
    }
  }
}
