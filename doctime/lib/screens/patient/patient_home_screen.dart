import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class PatientHomeScreen extends StatelessWidget { // <--- 1. غير الاسم هون
  const PatientHomeScreen({super.key});          // <--- 2. وهون

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: const Text("Patient"), // <--- 3. اكتب اسم الشاشة هون (مثلاً: Patient Home)
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (context) => const LoginScreen()),
                   (route) => false,
                 );
              }
            },
          ),
        ],
      ),
      body: Center(
        
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.construction, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "Under Construction 🚧",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("Waiting for Laith's Magic ✨"),
          ],
        ),
      ),
    );
  }
}