import 'package:flutter/material.dart';

class DoctorRequestsScreen extends StatelessWidget {
  const DoctorRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 نفس الألوان والستايل
    final Color primaryBlue = const Color(0xFF407CE2);
    final Color lightBg = const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pending Requests", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0), // نفس الحشوة الموحدة
        child: Column(
          children: [
            // 1️⃣ ملخص سريع (Header)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "You have 3 new requests waiting for approval.",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 2️⃣ قائمة الطلبات (List)
            // استخدمنا Expanded عشان تعبي باقي الشاشة
            Expanded(
              child: ListView.builder(
                itemCount: 3, // عدد وهمي للتجربة
                itemBuilder: (context, index) {
                  return _buildRequestCard(index, primaryBlue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت كرت الطلب
  Widget _buildRequestCard(int index, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // معلومات المريض
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue.shade100, width: 2)),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Patient Name ${index + 1}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text("12 Jan, 2025", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 15),
                        Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text("10:00 AM", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // أزرار القبول والرفض (كبار وواضحين)
          Row(
            children: [
              // زر الرفض
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 15),
              // زر القبول
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: primaryColor.withOpacity(0.4),
                  ),
                  child: const Text("Accept", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}