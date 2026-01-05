import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/common/chat_screen.dart'; // تأكد من مسار الـ ChatScreen

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final Color primaryBlue = const Color(0xFF407CE2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false, // شلنا سهم الرجوع عشان يكون شكلها زي التطبيقات
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 👇 التعديل السحري: شلنا orderBy عشان يشتغل فوراً بدون Index
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. معالجة الأخطاء (عشان نعرف لو في مشكلة)
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 2. حالة التحميل
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          var docs = snapshot.data!.docs;

          // 3. حالة لا يوجد رسائل
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text("No messages yet", style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var chatData = docs[index].data() as Map<String, dynamic>;
              
              // 🔍 تحديد الطرف الثاني
              List participants = chatData['participants'];
              String otherUserId = participants.firstWhere((id) => id != currentUser?.uid, orElse: () => "");

              if (otherUserId.isEmpty) return const SizedBox(); // حماية

              return FutureBuilder<DocumentSnapshot>(
                // بنجرب نجيب بياناته سواء كان دكتور أو مريض
                future: _getOtherUserData(otherUserId),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    // لودينج خفيف للكرت بس
                    return Container(
                      height: 80, 
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20)),
                    );
                  }

                  var userData = userSnap.data!.data() as Map<String, dynamic>?;
                  String name = userData?['name'] ?? "Unknown User";
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(
                        receiverId: otherUserId,
                        receiverName: name,
                      )));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: primaryBlue.withOpacity(0.1),
                            child: Icon(Icons.person, color: primaryBlue, size: 28),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  chatData['lastMessage'] ?? "Start chatting...", 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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

  // دالة ذكية بتدور بالـ doctors وبالـ users
  Future<DocumentSnapshot> _getOtherUserData(String uid) async {
    var doc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
    if (doc.exists) return doc;
    return await FirebaseFirestore.instance.collection('users').doc(uid).get();
  }
}