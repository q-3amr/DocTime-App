import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth/welcome_screen.dart'; 
import 'screens/patient/patient_home_screen.dart'; 

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // بنسمع للتغييرات في حالة المستخدم (دخول/خروج)
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        
        // 1. حالة الانتظار (بين ما الفايربيس يرد علينا)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. إذا في داتا (يعني المستخدم مسجل دخول) -> وده عالداشبورد
        if (snapshot.hasData) {
          return const PatientHomeScreen(); 
        }

        // 3. إذا ما في داتا (مش مسجل) -> وده على شاشة الترحيب
        return const WelcomeScreen();
      },
    );
  }
}