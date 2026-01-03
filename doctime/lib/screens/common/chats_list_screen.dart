import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 👇 لازم تعمل Import لشاشة المحادثة اللي عملناها قبل شوي
import 'chat_screen.dart'; 

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color primaryBlue = const Color(0xFF407CE2);
  final Color lightBg = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1️⃣ Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Messages",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: lightBg, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_square, color: Colors.black54),
                  )
                ],
              ),
              const SizedBox(height: 25),

              // 2️⃣ Search Bar
              Container(
                height: 55,
                decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(18)),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: "Search chats...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 3️⃣ قائمة المحادثات الحقيقية (Real-time)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // بنجيب الدكاترة اللي المريض حكا معهم (أو العكس)
                  // ملاحظة هندسية: في المشاريع الكبيرة بنستخدم كولكشن "conversations"، بس للسهولة رح نجيب الدكاترة
                  stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    var items = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var userData = items[index];
                        return _buildChatTile(
                          context,
                          id: userData.id,
                          name: userData['name'],
                          specialty: userData['specialty'],
                          primaryColor: primaryBlue,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, {required String id, required String name, required String specialty, required Color primaryColor}) {
    return GestureDetector(
      onTap: () {
        // 👇 الربط السحري: لما يكبس على الاسم، بيفتح الشات الحقيقي معه
        Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(
          receiverId: id,
          receiverName: "Dr. $name",
        )));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Dr. $name", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text("Now", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    specialty,
                    style: TextStyle(color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}