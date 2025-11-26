import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocTime Rahmah App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firestore Test")),
      body: FutureBuilder<DocumentSnapshot>(
        // بنجيب الدوكيومنت users/auto من فايرستور
        future: FirebaseFirestore.instance
            .collection("users")
            .doc("auto")
            .get(),
        builder: (context, snapshot) {
          // لسه بجيب البيانات
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // صار في خطأ
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          // ما لقى بيانات
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No data found"));
          }

          // في بيانات ✅
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'no name';
          final age = data['age']?.toString() ?? 'no age';

          return Center(
            child: Text(
              "Name: $name\nAge: $age",
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}
