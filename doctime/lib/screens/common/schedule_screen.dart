import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _buttonIndex = 0; // 0 للقادمة (Upcoming)، 1 للمكتملة (Completed)
  final User? user = FirebaseAuth.instance.currentUser;

  // ألوان التصميم اللي اعتمدناها
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
              const Text(
                "My Schedule",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 25),

              // 1️⃣ أزرار التبديل (Upcoming / Completed)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    _buildToggleButton("Upcoming", 0),
                    const SizedBox(width: 10),
                    _buildToggleButton("Completed", 1),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 2️⃣ جلب البيانات الحقيقية من الفايربيس
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('patient_id', isEqualTo: user?.uid) // بنجيب مواعيد المريض الحالي بس
                      .where('status', isEqualTo: _buttonIndex == 0 ? 'accepted' : 'completed')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 70, color: Colors.grey.shade300),
                            const SizedBox(height: 15),
                            Text("No appointments found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    var appointments = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        var data = appointments[index];
                        return _buildScheduleCard(
                          doctorName: data['doctor_name'],
                          date: data['date'].toString().substring(0, 10),
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
              style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  // ودجت كرت الموعد
  Widget _buildScheduleCard({required String doctorName, required String date, required Color primaryColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text("Confirmed Appointment", style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey), const SizedBox(width: 8), Text(date, style: const TextStyle(fontWeight: FontWeight.bold))]),
                const Row(children: [Icon(Icons.access_time_rounded, size: 18, color: Colors.grey), SizedBox(width: 8), Text("10:00 AM", style: TextStyle(fontWeight: FontWeight.bold))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}