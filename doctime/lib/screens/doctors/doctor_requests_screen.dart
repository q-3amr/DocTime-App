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

  // دالة لقبول الطلب
  Future<void> _acceptRequest(String docId) async {
    await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
      'status': 'accepted', // نغير الحالة لمقبول
    });
  }

  // دالة لرفض الطلب
  Future<void> _declineRequest(String docId) async {
    await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
      'status': 'declined', // نغير الحالة لمرفوض
    });
  }

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1️⃣ StreamBuilder لجلب البيانات الحقيقية
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // بنجيب بس المواعيد اللي حالتها "pending" وتابعة لهذا الدكتور
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('doctor_id', isEqualTo: "dummy_doc_id") // ⚠️ هام: لازم تكون نفس الـ ID اللي حجز فيه المريض
                    // .where('doctor_id', isEqualTo: user?.uid) // الصح نستخدم هاي بس عشان التجربة خليناها dummy
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  // حالة التحميل
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // حالة لا يوجد بيانات
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

                  // 2️⃣ عرض القائمة
                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var req = requests[index];
                      return _buildRequestCard(
                        name: req['patient_name'],
                        date: req['date'].toString().substring(0, 10), // تاريخ مختصر
                        docId: req.id, // آيدي المستند عشان التعديل
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

  // ودجت كرت الطلب
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
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(date, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // أزرار القبول والرفض الحقيقية
          Row(
            children: [
              // زر الرفض
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _declineRequest(docId), // 👇 ربطنا الرفض
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
                  onPressed: () => _acceptRequest(docId), // 👇 ربطنا القبول
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