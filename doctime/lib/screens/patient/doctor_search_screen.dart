import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_details_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  String searchQuery = ""; // لتخزين كلمة البحث
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Find Your Doctor", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          // 1️⃣ حقل البحث المتكتك
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: "Search by name or specialty...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // 2️⃣ قائمة الدكاترة من Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'doctor')
                  .where('isVerified', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No doctors found."));
                }

                // فلترة القائمة حسب البحث واستبعاد الدكتور الحالي
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  // استبعاد الدكتور الحالي إذا كان مسجل دخول
                  if (currentUser != null && doc.id == currentUser!.uid) {
                    return false;
                  }
                  // فلترة حسب البحث
                  String name = doc['name'].toString().toLowerCase();
                  String spec = doc['specialty'].toString().toLowerCase();
                  return name.contains(searchQuery) || spec.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24) ,
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    return _buildDoctorCard(
                      id: doc.id,
                      name: doc['name'],
                      specialty: doc['specialty'],
                      primaryColor: primaryBlue,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard({required String id, required String name, required String specialty, required Color primaryColor}) {
    return GestureDetector(
      onTap: () {
        // ننتقل لصفحة التفاصيل مع تمرير البيانات الحقيقية
        Navigator.push(context, MaterialPageRoute(builder: (c) => DoctorDetailsScreen(
          doctorName: name,
          specialty: specialty,
          doctorId: id, // أهم إشي الآيدي الحقيقي
        )));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 35),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dr. $name", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(specialty, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: primaryColor),
          ],
        ),
      ),
    );
  }
}