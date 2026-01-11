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
  String selectedFilter = "By Specialty"; // Default filter
  
  // List of medical specialties (same as signup)
  final List<String> specialties = [
    'All Specialties', // Added for "show all"
    'General Medicine',
    'Dentistry',
    'Cardiology',
    'Psychiatry',
    'Nutrition',
    'Urology',
    'Dermatology',
    'Gynecology & Obstetrics',
    'Orthopedics',
    'Pediatrics',
    'Internal Medicine',
    'Ophthalmology',
  ];
  
  String? selectedSpecialty = 'All Specialties';

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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
          
          // 2️⃣ Filter Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: _buildFilterSection(primaryBlue),
          ),
          
          // 2.5️⃣ Specialty Dropdown (shows only when "By Specialty" is selected)
          _buildSpecialtyDropdown(primaryBlue),

          // 3️⃣ قائمة الدكاترة من Firestore
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
                  bool matchesSearch = name.contains(searchQuery) || spec.contains(searchQuery);
                  
                  // فلترة حسب التخصص (إذا كان مفعّل)
                  bool matchesSpecialty = true;
                  if (selectedFilter == "By Specialty" && selectedSpecialty != 'All Specialties') {
                    matchesSpecialty = doc['specialty'] == selectedSpecialty;
                  }
                  
                  return matchesSearch && matchesSpecialty;
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

  Widget _buildFilterSection(Color primaryBlue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, color: primaryBlue, size: 22),
          const SizedBox(width: 12),
          const Text(
            "Filter by:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedFilter,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue, size: 22),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    'By Specialty',
                    'By Nearest', // GP2
                    'By Top Rated', // GP2
                  ].map((String filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Row(
                        children: [
                          Text(filter),
                          if (filter != 'By Specialty') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'GP2',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue == 'By Nearest' || newValue == 'By Top Rated') {
                      // Show coming soon message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$newValue will be available in GP2'),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      setState(() {
                        selectedFilter = newValue!;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyDropdown(Color primaryBlue) {
    if (selectedFilter != "By Specialty") return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedSpecialty,
            isExpanded: true,
            hint: const Text('Select Specialty'),
            icon: Icon(Icons.medical_services_outlined, color: primaryBlue, size: 20),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            items: specialties.map((String specialty) {
              return DropdownMenuItem<String>(
                value: specialty,
                child: Text(specialty),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedSpecialty = newValue;
              });
            },
          ),
        ),
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