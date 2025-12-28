import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = AuthService().currentUser;
  String name = "Loading...";
  String email = "Loading...";
  String role = "User"; // عشان نميز دكتور ولا مريض

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // دالة ذكية بتدور عالاسم سواء كان دكتور أو مريض
  void _fetchUserData() async {
    if (user != null) {
      setState(() => email = user!.email ?? "No Email");

      // 1. نجرب ندور في كولكشن المرضى
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          name = userDoc['name'];
          role = "Patient";
        });
        return;
      }

      // 2. إذا مش مريض، نجرب كولكشن الدكاترة
      DocumentSnapshot docDoc = await FirebaseFirestore.instance.collection('doctors').doc(user!.uid).get();
      if (docDoc.exists) {
        setState(() {
          name = docDoc['name'];
          role = "Doctor";
        });
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1️⃣ Header Title
              const Center(
                child: Text(
                  "My Profile",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
              ),
              
              const SizedBox(height: 30),

              // 2️⃣ Profile Card (Big Image & Info)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Row(
                  children: [
                    // صورة البروفايل
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryBlue, width: 2)),
                      child: const CircleAvatar(
                        radius: 35, // صورة كبيرة
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // المعلومات
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(role, style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    // زر التعديل
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_rounded, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 3️⃣ Settings Menu (Options)
              // استخدمنا Expanded عشان تعبي باقي الشاشة
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSettingsTile(Icons.person_outline_rounded, "Personal Info", Colors.blue),
                    _buildSettingsTile(Icons.notifications_none_rounded, "Notifications", Colors.orange),
                    _buildSettingsTile(Icons.security_rounded, "Security", Colors.green),
                    _buildSettingsTile(Icons.language_rounded, "Language", Colors.purple),
                    _buildSettingsTile(Icons.help_outline_rounded, "Help Center", Colors.teal),
                  ],
                ),
              ),

              // 4️⃣ Logout Button (Bottom)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded),
                      SizedBox(width: 10),
                      Text("Logout", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت خيار الإعدادات
  Widget _buildSettingsTile(IconData icon, String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}