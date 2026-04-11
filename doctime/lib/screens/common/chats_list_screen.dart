// ─────────────────────────────────────────────────────────────────────────────
// WHAT WAS CHANGED IN THIS FILE:
//
// 1. CHATS STREAM REPLACED:
//    BEFORE: StreamBuilder<QuerySnapshot> from FirebaseFirestore.instance directly:
//      .collection('chats').where('participants', arrayContains: uid).snapshots()
//    NOW: DatabaseService().streamChats(uid)
//
// 2. USER FETCH REPLACED + TYPE IMPROVED:
//    BEFORE: private _getOtherUserData(uid) calling Firestore directly, returning
//    a DocumentSnapshot. FutureBuilder<DocumentSnapshot> then cast it to Map.
//    NOW: DatabaseService().getUserById(uid) returns UserModel?.
//    FutureBuilder<UserModel?> — access .name directly, no Map casting.
//
// 3. kPrimaryBlue FROM CONSTANTS:
//    BEFORE: primaryBlue was a local Color variable.
//    NOW: kPrimaryBlue imported from utils/constants.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart'; // replaces direct Firestore calls
import '../../models/user.dart'; // FutureBuilder now uses UserModel? instead of DocumentSnapshot
import '../../utils/constants.dart'; // kPrimaryBlue — was a local variable before
import 'chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<dynamic>(
        stream:
            currentUser?.uid != null ? db.streamChats(currentUser!.uid) : null,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final chatData = docs[index].data() as Map<String, dynamic>;
              final List participants = chatData['participants'];
              final String otherUserId = participants.firstWhere(
                (id) => id != currentUser?.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox();

              return FutureBuilder<UserModel?>(
                future: db.getUserById(otherUserId),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }

                  if (userSnap.data == null) return const SizedBox.shrink();

                  final String name = userSnap.data!.name;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ChatScreen(
                          receiverId: otherUserId,
                          receiverName: name,
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: kPrimaryBlue.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: kPrimaryBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  chatData['lastMessage'] ??
                                      'Start chatting...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
