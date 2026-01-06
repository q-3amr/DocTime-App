import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // 🛠️ دالة تحويل البيانات لتاريخ حقيقي
  DateTime _parseDate(dynamic dateData) {
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now();
  }

  // 🎨 دالة تنسيق التاريخ والوقت بالشكل اللي طلبته
  String _formatDateTime(DateTime date) {
    // تنسيق التاريخ: 2025-01-07
    String datePart = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    // تنسيق الوقت: 11:42 PM
    int hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    String amPm = date.hour >= 12 ? 'PM' : 'AM';
    String timePart = "$hour:${date.minute.toString().padLeft(2, '0')} $amPm";

    return "$datePart | $timePart";
  }

  Future<void> _acceptRequest(String docId) async {
    await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
      'status': 'accepted',
    });
  }

  Future<void> _declineRequest(String docId) async {
    await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
      'status': 'declined', // تأكد إنها declined أو rejected حسب ما انت معتمد بالداتابيز
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('doctor_id', isEqualTo: user?.uid)
                    .where('status', isEqualTo: 'pending')
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
                          Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 15),
                          Text("No pending requests", style: TextStyle(color: Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }

                  var requests = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var req = requests[index];
                      var data = req.data() as Map<String, dynamic>;

                      // ✅ هون التعديل: تحويل وتنسيق التاريخ قبل تمريره للكارد
                      DateTime dateObj = _parseDate(data['date']);
                      String formattedString = _formatDateTime(dateObj);

                      return _buildRequestCard(
                        name: data['patient_name'] ?? 'Unknown',
                        date: formattedString, // صار يبعث التاريخ والوقت مرتبين
                        docId: req.id,
                        primaryColor: primaryBlue
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard({required String name, required String date, required String docId, required Color primaryColor}) {
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
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.grey.shade500), // غيرت الأيقونة لساعة عشان تناسب الوقت
                        const SizedBox(width: 6),
                        // التاريخ والوقت رح ينعرضوا هون
                        Text(date, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _declineRequest(docId),
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
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptRequest(docId),
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