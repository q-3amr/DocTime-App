import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
// 👇 تأكد إنك عامل Import لهدول الصفحات (تأكد من المسار)
import 'doctor_requests_screen.dart'; // صفحة الطلبات
import '../common/schedule_screen.dart'; // صفحة الجدول المشتركة
import '../common/profile_screen.dart'; // صفحة البروفايل المشتركة

// 1️⃣ هذا الكلاس هو "الرسيفر" (المسؤول عن التبديل)
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _selectedIndex = 0; // رقم القناة الحالية

  // 📺 قائمة القنوات (الصفحات)
  final List<Widget> _pages = [
    const DoctorHomeContent(),      // 0: الرئيسية (فصلناها تحت)
    const ScheduleScreen(),         // 1: الجدول (مشتركة)
    const DoctorRequestsScreen(),   // 2: الطلبات (للدكتور)
    const ProfileScreen(),          // 3: البروفايل (مشتركة وذكية)
  ];

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 👇 هون السر: IndexedStack هو اللي ببدل الصفحات
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      // الريموت كنترول (الشريط السفلي)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 14,
          unselectedFontSize: 14,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index), // أمر التبديل
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 28), label: "Dash"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded, size: 26), label: "Schedule"),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active_rounded, size: 28), label: "Requests"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 28), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

// 2️⃣ محتوى الصفحة الرئيسية للدكتور (الداشبورد) فصلناه هون
class DoctorHomeContent extends StatefulWidget {
  const DoctorHomeContent({super.key});

  @override
  State<DoctorHomeContent> createState() => _DoctorHomeContentState();
}

class _DoctorHomeContentState extends State<DoctorHomeContent> {
  final User? user = AuthService().currentUser;
  String doctorName = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchDoctorName();
  }

  void _fetchDoctorName() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('doctors').doc(user!.uid).get();  
        if (doc.exists && mounted) {
          setState(() { doctorName = doc['name'] ?? "Doctor"; });
        }
      } catch (e) {
        if (mounted) setState(() => doctorName = "Doctor");
      }
    }
  }

  void _handleLogout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);
    final Color lightBg = const Color(0xFFF5F7FA);
    const double defaultPadding = 24.0; 

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryBlue, width: 2.5)),
                      child: const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome back,", style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600)),
                        Text("Dr. $doctorName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.grey, size: 28),
                  onPressed: _handleLogout,
                )
              ],
            ),

            const SizedBox(height: 25),

            // Search Bar
            Container(
              height: 60,
              decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 30),
                  hintText: "Search patients...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Pending Requests", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text("You have 3 requests", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () {
                             // الانتقال للتاب رقم 2 (Requests)
                             // ملاحظة: للتنقل الداخلي بنحتاج نرفع الحالة للأب، بس حالياً خليه يفتح الصفحة كجديدة أسهل
                             Navigator.push(context, MaterialPageRoute(builder: (c) => const DoctorRequestsScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("View All", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 50),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text("Dashboard", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 15),

            // Grid Buttons
            Expanded(
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.05,
                children: [
                  _buildSquareBtn(Icons.checklist_rtl_rounded, "Requests", Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const DoctorRequestsScreen()));
                  }),
                  _buildSquareBtn(Icons.calendar_month_rounded, "My Schedule", Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const ScheduleScreen()));
                  }),
                  _buildSquareBtn(Icons.people_alt_rounded, "My Patients", Colors.purple, () {}),
                  _buildSquareBtn(Icons.settings_rounded, "Settings", Colors.teal, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareBtn(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.grey.shade50),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 38),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}