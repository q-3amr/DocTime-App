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

  @override
  Widget build(BuildContext context) {
    // رح نبني الواجهة بالخطوة الجاي، حالياً حط شاشة بيضاء فاضية عشان ما يضرب إيرور
    return const Scaffold(
      backgroundColor: Colors.white,
    );
  }
}
