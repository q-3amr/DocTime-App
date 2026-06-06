import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();
  final AiService _aiService = AiService();

  final List<ChatMessage> _messages = [];

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isTyping = false;
  bool _isInitialized = false;

  bool _isTriageComplete = false;
  String _triageUrgency = 'none';
  String _recommendedSpecialty = '';
  bool _hasConnectionError = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isTyping => _isTyping;
  bool get isTriageComplete => _isTriageComplete;
  String get triageUrgency => _triageUrgency;
  String get recommendedSpecialty => _recommendedSpecialty;
  bool get hasConnectionError => _hasConnectionError;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _speechService.initialize();
    await _ttsService.initialize();
    _messages.add(ChatMessage(
      text:
          'Hello! I am CareFlow AI Triage Assistant. How can I help you today?',
      sender: MessageSender.bot,
    ));
    notifyListeners();
    _isInitialized = true;
  }

  Future<void> sendTextMessage(String text) async {
    if (_isTyping || text.trim().isEmpty) return;
    await _processUserMessage(text.trim());
  }

  Future<void> startListening() async {
    if (_isListening) return;
    if (_isTyping) return;
    if (_isSpeaking) await _ttsService.stop();

    _isListening = true;
    notifyListeners();

    await _speechService.startListening(
      onResult: (words) {
        if (words.isNotEmpty) _processUserMessage(words);
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

  Future<void> _processUserMessage(String text) async {
    _messages.add(ChatMessage(text: text, sender: MessageSender.user));
    _isTyping = true;
    notifyListeners();

    final String aiResponseText = await _aiService.getAiResponse(text);

    _isTyping = false;

    if (aiResponseText.startsWith('Server error') ||
        aiResponseText.startsWith('Connection issue')) {
      _messages.removeLast();
      _onConnectionError();
    } else {
      try {
        final Map<String, dynamic> aiData = jsonDecode(aiResponseText);

        final String displayMessage =
            aiData['message'] ?? 'Error parsing message.';
        final String status = aiData['status'] ?? 'asking';
        final String urgency = aiData['urgency'] ?? 'none';
        final String specialty = aiData['specialty'] ?? 'none';

        _messages
            .add(ChatMessage(text: displayMessage, sender: MessageSender.bot));

        if (status == 'finished') {
          _isTriageComplete = true;
          _triageUrgency = urgency;
          if (specialty != 'none') {
            _recommendedSpecialty = specialty;
          }
        }
      } catch (e) {
        _messages.add(ChatMessage(
          text: "System Error: Couldn't parse response.",
          sender: MessageSender.bot,
        ));
        debugPrint('JSON Parse Error: $e');
      }
    }

    notifyListeners();
  }

  void _onConnectionError() {
    _hasConnectionError = true;
    notifyListeners();
    _hasConnectionError = false;
  }

  void clearMessages() {
    _messages.clear();
    _isTriageComplete = false;
    _triageUrgency = 'none';
    _recommendedSpecialty = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
