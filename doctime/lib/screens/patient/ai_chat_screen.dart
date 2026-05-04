import 'package:flutter/material.dart';
import '../../utils/constants.dart';

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
  // 2. تعريف المتغيرات اللي بتتحكم بالشاشة (State)
  final TextEditingController _messageController = TextEditingController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hello! I am DocTime AI Triage Assistant. How can I help you today?",
      isUser: false,
    ),
  ];
  // 3. دالة إرسال الرسالة
  void _sendMessage() {
    // التحقق: إذا المربع فاضي، لا تعمل إشي
    if (_messageController.text.trim().isEmpty) return;

    // تحديث الحالة (State) وإضافة الرسالة
    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text,
          isUser: true, // لأنها من المريض
        ),
      );
    });

    // مسح النص من المربع بعد الإرسال
    _messageController.clear();
  }

  // 4. دالة تنظيف الميموري (مهمة جداً هندسياً)
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. لون خلفية هادي عشان الفقاعات تبرز
      backgroundColor: Colors.grey[50],

      // 2. الشريط العلوي
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

      // 3. محتوى الشاشة (رح يكون عمود مقسم لجزئين)
      body: Column(
        children: [
          // الجزء العلوي: رح نعرض فيه لستة الرسائل (الخطوة الجاي)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              // عدد العناصر باللستة هو نفسه عدد الرسائل اللي عنا
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                // دالة رح نبنيها بالخطوة الجاي عشان ترسم شكل الفقاعة
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // الجزء السفلي: رح نحط فيه مربع الكتابة (الخطوة اللي بعدها)
          const Divider(height: 1), // خط فاصل رفيع
          Container(
            height: 70,
            color: Colors.white,
            child: const Center(child: Text("Input area")),
          ),
        ],
      ),
    );
  }

  // 5. تصميم فقاعة الرسالة
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      // تحديد المحاذاة: يمين للمريض، شمال للـ AI
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // تلوين الفقاعة: أزرق للمريض (من ثوابتك) وأبيض للـ AI
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
