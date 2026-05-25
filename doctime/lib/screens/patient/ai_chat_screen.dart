import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/ai_service.dart'; 
import 'package:flutter_markdown/flutter_markdown.dart';
import 'doctor_search_screen.dart';
import 'dart:convert';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  bool _isTriageComplete = false;
  String _recommendedSpecialty = "";
  String _triageUrgency = "none";
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  
  final AiService _aiService = AiService();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hello! I am DocTime AI Triage Assistant. How can I help you today?",
      isUser: false,
    ),
  ];
  Future<void> _sendMessage() async {
    if (_isTyping) return;
    if (_messageController.text.trim().isEmpty) return;
    final String userText = _messageController.text;

    _messageController.clear();

    setState(() {
      _messages.insert(0, ChatMessage(text: userText, isUser: true));
      _isTyping = true;
    });
    final String aiResponseText = await _aiService.getAiResponse(userText);

    setState(() {
      _isTyping = false;
      if (aiResponseText.startsWith('Server error') ||
          aiResponseText.startsWith('Connection issue')) {
        
        _messages.removeAt(0);

        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Connection error, check your connection and try again!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        try {
          
          final Map<String, dynamic> aiData = jsonDecode(aiResponseText);
          
          
          final String displayMessage = aiData['message'] ?? "Error parsing message.";
          final String status = aiData['status'] ?? "asking";
          final String urgency = aiData['urgency'] ?? "none";
          final String specialty = aiData['specialty'] ?? "none";

          
          _messages.insert(0, ChatMessage(text: displayMessage, isUser: false));

          
          if (status == "finished") {
            _isTriageComplete = true; 
            _triageUrgency = urgency; 
            
            if (specialty != "none") {
              _recommendedSpecialty = specialty; 
            }
          }
        } catch (e) {
          
           _messages.insert(0, ChatMessage(text: "System Error: Couldn't parse response.", isUser: false));
           print("JSON Parse Error: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          "AI Triage",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1, 
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, 
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          
          _isTriageComplete ? _buildCompletionButton() : _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? kPrimaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            
            bottomLeft:
                message.isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight:
                message.isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: MarkdownBody(
          data: message.text,
          styleSheet: MarkdownStyleSheet(
            
            p: TextStyle(
              color: message.isUser ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
            
            listBullet: TextStyle(
              color: message.isUser ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !_isTyping,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _isTyping
                      ? "Analyzing your symptoms..."
                      : "Describe your symptoms...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none, 
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _isTyping ? Colors.grey[400] : kPrimaryBlue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isTyping
                      ? Icons.hourglass_empty_rounded
                      : Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _isTyping ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildCompletionButton() {
  
  final Color backgroundColor;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  switch (_triageUrgency) {
    case 'red':
      backgroundColor = Colors.red;
      icon = Icons.warning_amber_rounded;
      label = 'EMERGENCY: Call Ambulance';
      onPressed = () {
        print('Calling ambulance...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Go to the Emergency Room immediately or call your local emergency number!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      };
      break;

    case 'yellow':
      backgroundColor = kPrimaryBlue;
      icon = Icons.search_rounded;
      label = 'Find $_recommendedSpecialty Doctors';
      onPressed = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorSearchScreen(
              initialSpecialty: _recommendedSpecialty,
            ),
          ),
        );
      };
      break;

    case 'green':
    default:
      backgroundColor = Colors.green;
      icon = Icons.home_rounded;
      label = 'Understood, Back to Home';
      onPressed = () => Navigator.pop(context);
      break;
  }

  
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
        ),
      ),
    ),
  );
}}
