import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// تأكد من مسار شاشة تسجيل الدخول عشان الـ Logout
import '../auth/login_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isDoctor = false;
  bool isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1️⃣ جلب البيانات (Logic)
  void _loadUserData() async {
    if (user == null) return;
    try {
      // فحص إذا دكتور
      var docRef = FirebaseFirestore.instance.collection('doctors').doc(user!.uid);
      var docSnap = await docRef.get();

      if (docSnap.exists) {
        setState(() {
          isDoctor = true;
          _nameController.text = docSnap.data()?['name'] ?? "";
          _bioController.text = docSnap.data()?['bio'] ?? ""; // النبذة
          _specialtyController.text = docSnap.data()?['specialty'] ?? "";
          isLoading = false;
        });
      } else {
        // فحص إذا مريض
        var patientSnap = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (patientSnap.exists) {
          setState(() {
            isDoctor = false;
            _nameController.text = patientSnap.data()?['name'] ?? "";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // 2️⃣ تحديث البيانات (Logic)
  void _updateProfile() async {
    if (user == null) return;
    
    String collection = isDoctor ? 'doctors' : 'users';
    Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
    };

    if (isDoctor) {
      data['bio'] = _bioController.text.trim();
      data['specialty'] = _specialtyController.text.trim();
    }

    await FirebaseFirestore.instance.collection(collection).doc(user!.uid).update(data);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully!")));
  }

  // 3️⃣ تسجيل الخروج
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // الرجوع لصفحة اللوج ان وحذف كل الصفحات السابقة من الذاكرة
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (c) => const LoginScreen()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر الخروج الأحمر
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF407CE2),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 30),

            _buildTextField("Full Name", _nameController, Icons.person),
            const SizedBox(height: 15),

            if (isDoctor) ...[
              _buildTextField("Specialty", _specialtyController, Icons.work),
              const SizedBox(height: 15),
              _buildTextField("About (Bio)", _bioController, Icons.info, maxLines: 3),
              const SizedBox(height: 15),
            ],

            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF407CE2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}