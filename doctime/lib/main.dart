import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_wrapper.dart'; 
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
      debugShowCheckedModeBanner: false, // بشيل شريطة Debug الحمراء
      title: 'DocTime',
      theme: ThemeData(
        useMaterial3: true,
        // غيرت اللون للأزرق (لون طبي) بدال الأحمر، بس بتقدر ترجعه اذا بدك
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), 
      ),
      
      home: const AuthWrapper(), 
    );
  }
}
