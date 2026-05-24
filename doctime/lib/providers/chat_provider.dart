import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';

class ChatProvider extends ChangeNotifier {
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();

  final List<ChatMessage> _messages = [];

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _speechService.initialize();
    await _ttsService.initialize();
    _isInitialized = true;
  }

  Future<void> sendTextMessage(String text) async {
    _messages.add(ChatMessage(text: text, sender: MessageSender.user));
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _messages.add(
      ChatMessage(text: 'Got it! You said: "$text"', sender: MessageSender.bot),
    );
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_isListening) return;
    if (_isSpeaking) await _ttsService.stop();

    _isListening = true;
    notifyListeners();

    await _speechService.startListening(
      onResult: (words) {
        if (words.isNotEmpty) _addUserMessage(words);
      },
      onDone: () {
        _isListening = false;
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
    _isListening = false;
    notifyListeners();
  }

  Future<void> speakMessage(ChatMessage message) async {
    _isSpeaking = true;
    notifyListeners();
    await _ttsService.speak(message.text);
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> speakLastBotMessage() async {
    final last = _messages.lastWhere(
      (m) => m.sender == MessageSender.bot,
      orElse: () => ChatMessage(text: '', sender: MessageSender.bot),
    );
    if (last.text.isNotEmpty) await speakMessage(last);
  }

  void _addUserMessage(String text) {
    _messages.add(ChatMessage(text: text, sender: MessageSender.user));
    notifyListeners();

    _addBotEcho(text);
  }

  void _addBotEcho(String userText) {
    _messages.add(
      ChatMessage(text: 'You said: "$userText"', sender: MessageSender.bot),
    );
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
