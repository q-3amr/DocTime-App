import 'package:flutter/material.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // قائمة الرسائل (وهمية للتجربة)
  final List<Map<String, String>> _messages = [
    {'sender': 'bot', 'text': 'Hello! I am DocTime AI. How can I help you today?'},
  ];

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    setState(() {
      // 1. إضافة رسالة المستخدم
      _messages.add({'sender': 'user', 'text': _controller.text});
      
      // 2. محاكاة رد الذكاء الاصطناعي (تأخير بسيط)
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _messages.add({
              'sender': 'bot', 
              'text': 'I understand your concern. Based on your symptoms, I recommend booking an appointment with a General Practitioner. Would you like me to find one?'
            });
            _scrollToBottom();
          });
        }
      });

      _controller.clear();
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    // عشان تنزل الشاشة لآخر رسالة تلقائياً
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
    final Color lightBg = const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: Colors.white,
      // 1️⃣ Header (Fixed)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.purple, size: 24),
            ),
            const SizedBox(width: 10),
            const Text("AI Assistant", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
      ),
      
      body: Column(
        children: [
          // 2️⃣ Chat Body (Scrollable)
          Expanded(
            child: Container(
              color: lightBg, // خلفية مختلفة للشات
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  return _buildMessageBubble(msg['text']!, isUser, primaryBlue);
                },
              ),
            ),
          ),

          // 3️⃣ Input Area (Fixed at bottom)
          Container(
            padding: const EdgeInsets.all(20), // حشوة كبيرة
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: lightBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ask about symptoms...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // زر الإرسال
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ودجت فقاعة الرسالة (Bubble)
  Widget _buildMessageBubble(String text, bool isUser, Color primaryColor) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // عرض أقصى 75%
        decoration: BoxDecoration(
          color: isUser ? primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0), // ذيل الفقاعة
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
          ),
          boxShadow: [
            if (!isUser) // ظل بس لرسائل البوت
              BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
            height: 1.4, // تباعد أسطر مريح للقراءة
          ),
        ),
      ),
    );
  }
}