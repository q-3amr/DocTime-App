import 'package:flutter/material.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);
    final Color lightBg = const Color(0xFFF5F7FA);

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
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(18),
                ),
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

              // 3️⃣ Active Users (Stories Style - Optional but looks cool)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryBlue, width: 2.5)),
                            child: const CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text("Dr. Name", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // 4️⃣ Chats List
              Expanded(
                child: ListView.builder(
                  itemCount: 4, // عدد المحادثات
                  itemBuilder: (context, index) {
                    return _buildChatTile(index, primaryBlue);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت كرت المحادثة
  Widget _buildChatTile(int index, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // الصورة
          Stack(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              if (index == 0) // نقطة أونلاين لأول واحد بس
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 15),
          // الاسم والرسالة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Dr. Qusai Ahmed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text("10:30 AM", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your appointment is confirmed.", 
                      style: TextStyle(color: index == 0 ? Colors.black87 : Colors.grey.shade500, fontWeight: index == 0 ? FontWeight.w700 : FontWeight.w500),
                    ),
                    if (index == 0) // عداد رسائل غير مقروءة
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                        child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}