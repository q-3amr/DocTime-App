import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  Future<void> initialize() async {
    final languages = await _tts.getLanguages as List?;
    final hasArabic =
        languages?.any((l) => l.toString().toLowerCase().contains('ar')) ??
        false;

    if (hasArabic) {
      await _tts.setLanguage('ar-SA');
    } else {
      await _tts.setLanguage('en-US');
    }

    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) => _isSpeaking = false);
  }

  bool get isSpeaking => _isSpeaking;

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    if (isArabic) {
      await _tts.setLanguage('ar-SA');
    } else {
      await _tts.setLanguage('en-US');
    }

    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
