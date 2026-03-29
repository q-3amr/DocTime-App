// ─────────────────────────────────────────────────────────────────────────────
// WHAT WAS CHANGED IN THIS FILE:
//
// 1. FIRESTORE STREAM REPLACED + TYPE IMPROVED:
//    BEFORE: StreamBuilder<QuerySnapshot> from FirebaseFirestore.instance directly
//    with raw doc['name'], doc['specialty'], doc.id access.
//    NOW: DatabaseService().streamDoctors() returns Stream<List<UserModel>>.
//    StreamBuilder<List<UserModel>> — access doctor.name, .specialty, .id directly.
//
// 2. SPECIALTIES LIST REPLACED:
//    BEFORE: had its own local List<String> specialties = [...] copy-pasted from others.
//    NOW: kSpecialties from utils/constants.dart (also used in signup + profile).
//
// 3. kPrimaryBlue FROM CONSTANTS:
//    BEFORE: primaryBlue was a local Color variable.
//    NOW: kPrimaryBlue imported from utils/constants.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart'; // replaces direct Firestore stream
import '../../models/user.dart'; // StreamBuilder now uses List<UserModel> instead of QuerySnapshot
import '../../utils/constants.dart'; // kPrimaryBlue + kSpecialties — were local copies before
import 'doctor_details_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final _db = DatabaseService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String searchQuery = '';
  String selectedFilter = 'By Specialty';
  String? selectedSpecialty = 'All Specialties';

  // All specialties + "All" option for the filter dropdown.
  static const List<String> _filterSpecialties = [
    'All Specialties',
    ...kSpecialties,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find Your Doctor',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                onChanged:
                    (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search by name or specialty...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: _buildFilterSection(),
          ),

          // Specialty dropdown (shown only when By Specialty is active)
          _buildSpecialtyDropdown(),

          // Doctor list
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _db.streamDoctors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No doctors found.'));
                }

                final filtered =
                    snapshot.data!.where((doctor) {
                      // Exclude current user if they are a doctor browsing.
                      if (currentUser != null &&
                          doctor.id == currentUser!.uid) {
                        return false;
                      }

                      final name = doctor.name.toLowerCase();
                      final spec =
                          (doctor.specialty ?? '').toLowerCase();
                      final matchesSearch =
                          name.contains(searchQuery) ||
                          spec.contains(searchQuery);

                      bool matchesSpecialty = true;
                      if (selectedFilter == 'By Specialty' &&
                          selectedSpecialty != 'All Specialties') {
                        matchesSpecialty =
                            doctor.specialty == selectedSpecialty;
                      }

                      return matchesSearch && matchesSpecialty;
                    }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No doctors match your search.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doctor = filtered[index];
                    return _buildDoctorCard(doctor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
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
          const Icon(Icons.filter_list_rounded, color: kPrimaryBlue, size: 22),
          const SizedBox(width: 12),
          const Text(
            'Filter by:',
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
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: kPrimaryBlue,
                    size: 22,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  items:
                      ['By Specialty', 'By Nearest', 'By Top Rated'].map((
                        String filter,
                      ) {
                        return DropdownMenuItem<String>(
                          value: filter,
                          child: Row(
                            children: [
                              Text(filter),
                              if (filter != 'By Specialty') ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
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
                    if (newValue == 'By Nearest' ||
                        newValue == 'By Top Rated') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$newValue will be available in GP2'),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      setState(() => selectedFilter = newValue!);
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

  Widget _buildSpecialtyDropdown() {
    if (selectedFilter != 'By Specialty') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: kPrimaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryBlue.withOpacity(0.3)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedSpecialty,
            isExpanded: true,
            hint: const Text('Select Specialty'),
            icon: const Icon(
              Icons.medical_services_outlined,
              color: kPrimaryBlue,
              size: 20,
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kPrimaryBlue,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            items:
                _filterSpecialties.map((String specialty) {
                  return DropdownMenuItem<String>(
                    value: specialty,
                    child: Text(specialty),
                  );
                }).toList(),
            onChanged:
                (String? newValue) =>
                    setState(() => selectedSpecialty = newValue),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(UserModel doctor) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (c) => DoctorDetailsScreen(
                    doctorName: doctor.name,
                    specialty: doctor.specialty ?? 'General',
                    doctorId: doctor.id,
                  ),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
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
                  Text(
                    'Dr. ${doctor.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    doctor.specialty ?? 'General',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: kPrimaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
