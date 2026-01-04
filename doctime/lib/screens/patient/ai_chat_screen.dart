import 'package:flutter/material.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // قائمة الرسائل (بداية المحادثة)
  final List<Map<String, String>> _messages = [
    {'sender': 'bot', 'text': 'Hello! I am DocTime AI. 🤖\nDescribe your symptoms, and I will suggest the right specialist for you.'},
  ];

  bool _isTyping = false;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    // 1. إضافة رسالة المستخدم
    setState(() {
      _messages.add({'sender': 'user', 'text': _controller.text.trim()});
      _isTyping = true; // البوت بكتب...
    });
    
    _controller.clear();
    _scrollToBottom();

    // 2. محاكاة رد الذكاء الاصطناعي (تأخير 1.5 ثانية)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'sender': 'bot', 
            'text': _getAIResponse(_messages.last['text']!) // دالة الرد الذكي
          });
          _scrollToBottom();
        });
      }
    });
  }

  // 🧠 دالة الردود (منطق بسيط لـ GP1)
  String _getAIResponse(String input) {
    input = input.toLowerCase();
    if (input.contains('headache') || input.contains('head')) {
      return "Based on your symptoms (Headache), I recommend seeing a **Neurologist** or a **General Practitioner**. \n\nWould you like to book an appointment now?";
    } else if (input.contains('heart') || input.contains('pain') || input.contains('chest')) {
      return "Chest pain can be serious. Please consult a **Cardiologist** immediately. \n\nGo to 'Find Doctor' > 'Cardiologist'.";
    } else if (input.contains('tooth') || input.contains('teeth')) {
      return "It seems you have dental issues. A **Dentist** is the right choice for you.";
    } else if (input.contains('eye') || input.contains('vision')) {
      return "For vision problems, please visit an **Ophthalmologist**.";
    } else if (input.contains('skin') || input.contains('rash')) {
      return "You should consult a **Dermatologist** for skin-related issues.";
    } else {
      return "I'm not sure about this symptom yet. Please consult a **General Practitioner** for a checkup.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("AI Assistant", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // مساحة الشات
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 10),
                      child: Text("AI is typing...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ),
                  );
                }
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return _buildChatBubble(msg['text']!, isUser, primaryBlue);
              },
            ),
          ),

          // حقل الإدخال
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your symptoms...",
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: primaryBlue,
                  elevation: 2,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, Color color) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? color : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}