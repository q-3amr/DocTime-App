import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // 📍 تعليق: مكتبة تحديد الموقع الجغرافي
import 'dart:math'
    show cos, sqrt, asin; // 📍 تعليق: مكتبة الحسابات الرياضية للمعادلات
import '../../services/database_service.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
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

  // 📍 تعليق: متغير لتخزين إحداثيات موقع المريض (Latitude & Longitude)
  Position? _userPosition;

  static const List<String> _filterSpecialties = [
    'All Specialties',
    ...kSpecialties,
  ];

  // 📍 تعليق: دالة رياضية (Haversine) لحساب المسافة الجوية بين نقطتين بالكيلومتر
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // 📍 تعليق: دالة لطلب الإذن من المستخدم وجلب موقعه الحالي من الـ GPS
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userPosition = position; // حفظ الموقع
      selectedFilter = 'By Nearest'; // تفعيل فلتر الأقرب
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find Your Doctor',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          // بار البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                onChanged: (value) =>
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

          // قسم الفلترة
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: _buildFilterSection(),
          ),

          // دروب داون التخصصات
          _buildSpecialtyDropdown(),

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

                // 📍 تعليق: المرحلة الأولى - الفلترة حسب النص (البحث) وحسب التخصص المختار
                List<UserModel> filtered = snapshot.data!.where((doctor) {
                  if (currentUser != null && doctor.id == currentUser!.uid)
                    return false;
                  final name = doctor.name.toLowerCase();
                  final spec = (doctor.specialty ?? '').toLowerCase();
                  final matchesSearch =
                      name.contains(searchQuery) || spec.contains(searchQuery);

                  bool matchesSpecialty = true;
                  if (selectedSpecialty != 'All Specialties') {
                    matchesSpecialty = doctor.specialty == selectedSpecialty;
                  }
                  return matchesSearch && matchesSpecialty;
                }).toList();

                // 📍 تعليق: المرحلة الثانية - إذا كان المريض اختار "الأقرب" وموقعه متوفر
                if (selectedFilter == 'By Nearest' && _userPosition != null) {
                  for (var doc in filtered) {
                    if (doc.latitude != null && doc.longitude != null) {
                      // حساب المسافة لكل دكتور وتخزينها في الموديل
                      doc.distance = _calculateDistance(
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                        doc.latitude!,
                        doc.longitude!,
                      );
                    }
                  }
                  // ترتيب القائمة من الأقرب للأبعد (الرقم الأصغر أولاً)
                  filtered.sort((a, b) =>
                      (a.distance ?? 99999).compareTo(b.distance ?? 99999));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildDoctorCard(filtered[index]),
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
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, color: kPrimaryBlue, size: 22),
          const SizedBox(width: 12),
          const Text('Filter by:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedFilter,
                isExpanded: true,
                items: ['By Specialty', 'By Nearest']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue == 'By Nearest') {
                    // 📍 تعليق: استدعاء دالة جلب الموقع عند اختيار فلتر الأقرب
                    _getCurrentLocation();
                  } else {
                    setState(() => selectedFilter = newValue!);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          // 📍 تعليق: استخدام withValues بدل withOpacity ليتناسب مع تحديثات فلاتر الجديدة
          color: kPrimaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryBlue.withValues(alpha: 0.3)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedSpecialty,
            isExpanded: true,
            items: _filterSpecialties
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => setState(() => selectedSpecialty = val),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(UserModel doctor) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => DoctorDetailsScreen(
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
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15)
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
                  Text('Dr. ${doctor.name}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(doctor.specialty ?? 'General',
                      style: TextStyle(color: Colors.grey.shade500)),

                  // 📍 تعليق: إظهار المسافة بالكيلومتر فقط إذا كانت محسوبة (أي عند تفعيل فلتر الأقرب)
                  if (doctor.distance != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${doctor.distance!.toStringAsFixed(1)} km away', // عرض رقم واحد بعد الفاصلة
                        style: const TextStyle(
                            color: kPrimaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: kPrimaryBlue),
          ],
        ),
      ),
    );
  }
}
