import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/ai_service.dart'; // تأكد من مسار الملف عندك صح
import 'package:flutter_markdown/flutter_markdown.dart';

// 1. الكلاس تبع الرسالة (الهيكل)
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
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  // استدعينا الـ Service عشان الشاشة تقدر تستخدمها
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
        // إذا إيرور: بنشيل رسالة المريض اللي انبعثت عشان يقدر يرجع يبعثها
        _messages.removeAt(0);

        // وبنطلعله الإيرور كإشعار أحمر منبثق تحت مش كرسالة شات
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Connection error, check your connection and try again!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // إذا الرد طبيعي وما فيه إيرور، بنضيفه كرسالة شات عادية
        // بنضيف الرسالة زي ما هي
        _messages.insert(0, ChatMessage(text: aiResponseText, isUser: false));

        // بنفحص إذا البوت قرر ينهي المحادثة
        if (aiResponseText
            .contains("I recommend you book an appointment with")) {
          // استخدام الـ Regex عشان نقص كل اشي بعد كلمة with a أو with an
          // وبنقص النقطة اللي بآخر السطر إذا موجودة
          RegExp regExp = RegExp(r"appointment with (?:a |an )?(.*?)(?:\.|$)");
          var match = regExp.firstMatch(aiResponseText);

          String extractedSpecialty = "Specialist"; // قيمة افتراضية لو فشل القص

          if (match != null && match.groupCount >= 1) {
            // بنسحب التخصص وبنشيل المسافات الزايدة
            extractedSpecialty = match.group(1)!.trim();
          }

          setState(() {
            _isTriageComplete = true; // بنغير حالة الشاشة
            _recommendedSpecialty =
                extractedSpecialty; // بنخزن التخصص اللي قصيناه
          });
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
        elevation: 1, // ظل خفيف جداً عشان يفصل الـ AppBar عن الشاشة
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // ضيف هاد السطر عشان اللستة تنبني من تحت لفوق
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          // إذا خلص الفرز بنعرض زر الانتقال، إذا لسه بنعرض مربع الكتابة
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
            // حركة جمالية: الزاوية اللي تحت جهة المرسل بتكون حادة
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
            // هون بنتحكم بلون النص الأساسي (الفقرات)
            p: TextStyle(
              color: message.isUser ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
            // إذا البوت قرر يبعث نقاط، بنخلي لونها صح
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
                    borderSide: BorderSide.none, // بدون حدود واضحة
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      width: double.infinity,
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            // هون رح يجي كود الانتقال (Navigator)
            print(
                "Routing to doctors list with filter: $_recommendedSpecialty");
          },
          child: Text(
            // هون دمجنا اسم التخصص اللي استخرجناه جوا النص تبع الزر
            "Find $_recommendedSpecialty Doctors",
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
