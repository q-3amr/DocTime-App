import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _buttonIndex = 0; // 0 for Upcoming, 1 for Completed

  // ألوان التصميم
  final Color primaryBlue = const Color(0xFF407CE2);
  final Color lightBg = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // نفس الحشوة الموحدة
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1️⃣ Header
              const Text(
                "My Schedule",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              
              const SizedBox(height: 25),

              // 2️⃣ Toggle Switch (Upcoming / Completed)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildToggleButton("Upcoming", 0),
                    const SizedBox(width: 10),
                    _buildToggleButton("Completed", 1),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 3️⃣ Appointments List (Expanded to fill screen)
              Expanded(
                child: ListView.builder(
                  itemCount: 3, // عدد وهمي
                  itemBuilder: (context, index) {
                    return _buildScheduleCard(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت كبسة التبديل
  Widget _buildToggleButton(String text, int index) {
    bool isSelected = _buttonIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _buttonIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ودجت كرت الموعد
  Widget _buildScheduleCard(int index) {
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
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // تفاصيل الدكتور/المريض
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue.shade100)),
                child: const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.blue,
                  // أيقونة طبيب أو مريض حسب المستخدم
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dr. Qusai Ahmed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text("Software Engineer", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // تفاصيل الوقت والتاريخ (بمربعات رمادية فاتحة)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text("Mon, 12 Jan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text("10:00 AM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // أزرار التحكم (Cancel / Reschedule)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 5,
                    shadowColor: primaryBlue.withOpacity(0.3),
                  ),
                  child: const Text("Reschedule", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}