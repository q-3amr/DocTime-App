import 'package:flutter/material.dart';

class PatientHomeScreen extends StatelessWidget { // <--- 1. غير الاسم هون
  const PatientHomeScreen({super.key});          // <--- 2. وهون

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient"), // <--- 3. اكتب اسم الشاشة هون (مثلاً: Patient Home)
        backgroundColor: Colors.blue,
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