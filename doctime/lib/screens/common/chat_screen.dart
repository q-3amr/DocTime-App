import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;   // آيدي الشخص اللي بنبعث له (دكتور أو مريض)
  final String receiverName; // اسمه عشان نعرضه بالـ AppBar

  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color primaryBlue = const Color(0xFF407CE2);

  // 📝 دالة إرسال الرسالة للـ Firestore
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String msg = _messageController.text.trim();
    _messageController.clear(); // بنمسح الحقل فوراً عشان السرعة

    await FirebaseFirestore.instance.collection('chats').add({
      'senderId': currentUser?.uid,
      'receiverId': widget.receiverId,
      'message': msg,
      'timestamp': FieldValue.serverTimestamp(), // وقت السيرفر عشان الترتيب
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. عرض الرسائل بلحظتها (Real-time)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('timestamp', descending: true) // الجديد تحت
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // فلترة الرسائل لتظهر فقط بين هدول الشخصين (A و B)
                var messages = snapshot.data!.docs.where((doc) {
                  String sId = doc['senderId'];
                  String rId = doc['receiverId'];
                  return (sId == currentUser?.uid && rId == widget.receiverId) ||
                         (sId == widget.receiverId && rId == currentUser?.uid);
                }).toList();

                return ListView.builder(
                  reverse: true, // عشان السكرول يبدأ من تحت
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index];
                    bool isMe = data['senderId'] == currentUser?.uid;
                    return _buildChatBubble(data['message'], isMe);
                  },
                );
              },
            ),
          ),

          // 2. حقل الكتابة (Input)
          _buildInputArea(),
        ],
      ),
    );
  }

  // ويدجت فقاعة الرسالة
  Widget _buildChatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? primaryBlue : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16)),
      ),
    );
  }

  // ويدجت منطقة الإدخال
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: "Write a message...", border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: primaryBlue,
            child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: _sendMessage),
          ),
        ],
      ),
    );
  }
}