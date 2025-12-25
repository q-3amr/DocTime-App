import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'screens/auth/welcome_screen.dart'; 
import 'screens/patient/patient_home_screen.dart'; 
import 'screens/doctors/doctor_home_screen.dart'; 

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('doctors').doc(user.uid).get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                return const PatientHomeScreen(); // Must be Updated to DoctorHomeScreen
              }
              return const PatientHomeScreen();
            },
          );
        }
        return const WelcomeScreen();
      },
    );
  }
}