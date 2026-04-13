import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorReviewsScreen extends StatefulWidget {
  const DoctorReviewsScreen({super.key});

  @override
  State<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends State<DoctorReviewsScreen> {
  @override
  void initState() {
    super.initState();
    // تصفير النقطة الزرقاء بمجرد الدخول
    _markReviewsAsSeen();
  }

  void _markReviewsAsSeen() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // جلب المواعيد الخاصة بهذا الدكتور فقط (لتجنب طلب Index معقد من فايربيس)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctor_id', isEqualTo: uid)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // الفلترة تتم هنا برمجياً (Client-side) لحل مشكلة الـ Index
        if (data['hasFeedback'] == true && data['isReviewSeen'] != true) {
          batch.update(doc.reference, {'isReviewSeen': true});
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
        // إعادة بناء الواجهة لإخفاء النقطة الزرقاء إذا كانت موجودة
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error updating reviews status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Patient Reviews',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctor_id', isEqualTo: uid)
            .where('hasFeedback', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          // ترتيب المراجعات: الأحدث يظهر في الأعلى
          docs.sort((a, b) => b['date'].compareTo(a['date']));

          if (docs.isEmpty) {
            return const Center(
              child: Text('No reviews yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data['patient_name'] ?? 'Patient',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Row(
                          children: [
                            Icon(Icons.star_rounded,
                                color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text("5.0",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['feedback_text'] ?? 'No comment provided.',
                      style:
                          TextStyle(color: Colors.grey.shade700, height: 1.4),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
