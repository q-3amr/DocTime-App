// ─────────────────────────────────────────────────────────────────────────────
// WHAT WAS CHANGED IN THIS FILE:
//
// 1. ALL FIRESTORE CALLS REPLACED:
//    BEFORE: had a FirebaseFirestore _firestore instance field and called it directly
//    for: adding messages, updating the chat room document, and the messages stream.
//    NOW: DatabaseService().sendMessage(), updateChatRoom(), streamMessages()
//
// 2. kPrimaryBlue FROM CONSTANTS:
//    BEFORE: primaryBlue was a local Color variable.
//    NOW: kPrimaryBlue imported from utils/constants.dart.
//
// NOTE: cloud_firestore is still imported here only to use Timestamp.now()
// for the message timestamp. This is acceptable as it’s a data-type import,
// not a database operation.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // only for Timestamp type, not DB operations
import '../../services/database_service.dart'; // replaces all direct Firestore DB calls
import '../../utils/constants.dart'; // kPrimaryBlue — was a local variable before

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    _markAsRead(); // أول ما تفتح الشاشة بنخلي الرسائل مقروءة
  }

  void _markAsRead() async {
    final chatRoomId = _chatRoomId(_currentUserId, widget.receiverId);
    await _db.updateChatRoom(chatRoomId, {
      'isRead': true, // هيك النقطة رح تختفي من الـ Dashboard والـ List
    });
  }

  final _db = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String _chatRoomId(String user1, String user2) =>
      user1.compareTo(user2) > 0 ? '${user1}_$user2' : '${user2}_$user1';

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final msg = _messageController.text.trim();
    _messageController.clear();

    final chatRoomId = _chatRoomId(_currentUserId, widget.receiverId);
    final now = Timestamp.now();

    await _db.sendMessage(chatRoomId, {
      'senderId': _currentUserId,
      'receiverId': widget.receiverId,
      'message': msg,
      'timestamp': now,
    });

    await _db.updateChatRoom(chatRoomId, {
      'participants': [_currentUserId, widget.receiverId],
      'lastMessage': msg,
      'lastMessageTime': now,
      'users': {_currentUserId: true, widget.receiverId: true},
      'lastMessageSenderId': _currentUserId,
      'isRead': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomId = _chatRoomId(_currentUserId, widget.receiverId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.receiverName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<dynamic>(
              stream: _db.streamMessages(chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUserId;
                    return _buildChatBubble(data['message'], isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isMe ? kPrimaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: kPrimaryBlue,
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
