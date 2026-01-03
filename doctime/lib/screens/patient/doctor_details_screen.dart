import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctime/screens/common/chat_screen.dart';
class DoctorDetailsScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  // ضفنا الـ ID عشان نعرف لمين نبعث الحجز (مؤقتاً ممكن نمرره أو نجيبه)
  final String doctorId; 

  const DoctorDetailsScreen({
    super.key, 
    required this.doctorName, 
    required this.specialty,
    this.doctorId = "dummy_doc_id", // قيمة افتراضية للتجربة
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  bool _isLoading = false;

  // دالة الحجز الحقيقي (Firestore)
  Future<void> _bookAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. نجيب اسم المريض الحالي
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String patientName = userDoc.exists ? userDoc['name'] : "Unknown Patient";

      // 2. نجهز بيانات الحجز
      await FirebaseFirestore.instance.collection('appointments').add({
        'doctor_id': widget.doctorId,       // آيدي الدكتور (عشان يعرف الطلب إله)
        'doctor_name': widget.doctorName,   // اسم الدكتور
        'patient_id': user.uid,             // آيدي المريض
        'patient_name': patientName,        // اسم المريض
        'date': DateTime.now().toString(),  // تاريخ الطلب
        'status': 'pending',                // الحالة: معلق (لسا ما وافق الدكتور)
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // 3. عرض رسالة نجاح
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Success!"),
            content: const Text("Your appointment request has been sent to the doctor."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // سكر الديالوج
                  Navigator.pop(context); // ارجع للصفحة الرئيسية
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1️⃣ صورة الدكتور (SliverAppBar)
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.doctorName),
              background: Image.network(
                "https://img.freepik.com/free-photo/doctor-with-his-arms-crossed-white-background_1368-5790.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2️⃣ تفاصيل الدكتور
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم والتخصص
                  Text(widget.doctorName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(widget.specialty, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  
                  const SizedBox(height: 20),
                  
                  // إحصائيات سريعة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(Icons.people, "1000+", "Patients"),
                      _buildInfoChip(Icons.star, "4.8", "Rating"),
                      _buildInfoChip(Icons.work, "5 Yrs", "Experience"),
                    ],
                  ),
                  Container(
  height: 56,
  width: 56,
  decoration: BoxDecoration(
    color: primaryBlue.withOpacity(0.1),
    borderRadius: BorderRadius.circular(16),
  ),
  child: IconButton(
    icon: Icon(Icons.chat_bubble_outline_rounded, color: primaryBlue),
    onPressed: () {
      // 👇 هون التربيط السحري: بنفتح الشات وبنمرر معلومات الدكتور
      Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(
        receiverId: widget.doctorId,    // الآيدي الحقيقي للدكتور اللي جاي من الداتابيس
        receiverName: widget.doctorName, // اسم الدكتور اللي رح يظهر فوق بالشات
      )));
    },
  ),
),
                  const SizedBox(height: 25),

                  const Text("About Doctor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    "Dr. ${widget.doctorName} is a top specialist in ${widget.specialty}. He has received multiple awards and is dedicated to patient care.",
                    style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                  ),

                  const SizedBox(height: 100), // مسافة عشان الزر ما يغطي الكلام
                ],
              ),
            ),
          ),
        ],
      ),

      // 3️⃣ زر الحجز (Floating Button)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _bookAppointment, // 👇 ربطنا الدالة هون
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Book Appointment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF407CE2), size: 24),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}