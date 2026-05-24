import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _stt = SpeechToText();

  bool _isAvailable = false;

  bool get isListening => _stt.isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    _isAvailable = await _stt.initialize(
      onError: (error) => print('STT error: $error'),
    );
    return _isAvailable;
  }

  Future<void> startListening({
    required void Function(String words) onResult,
    required void Function() onDone,
  }) async {
    if (!_isAvailable) await initialize();
    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  Future<void> cancel() async {
    await _stt.cancel();
  }
}
