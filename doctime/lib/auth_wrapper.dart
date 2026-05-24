// ─────────────────────────────────────────────────────────────────────────────
// WHAT WAS CHANGED IN THIS FILE:
//
// 1. DIRECT FIRESTORE CALL REPLACED:
//    BEFORE: FutureBuilder<DocumentSnapshot> calling
//      FirebaseFirestore.instance.collection('users').doc(user.uid).get()
//    NOW: DatabaseService().getUserById(user.uid) — goes through the service layer.
//
// 2. SECURITY BUG FIXED:
//    BEFORE: AuthWrapper showed DoctorHomeScreen for ALL doctors — including
//    unverified ones. An unverified doctor blocked at login could bypass
//    that check by force-closing and reopening the app.
//    NOW: isVerified is checked here too. Unverified doctors see a
//    'Pending Approval' screen with a sign-out button until an admin approves.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/guest/guest_home_screen.dart';
import 'screens/patient/patient_home_screen.dart';
import 'screens/doctors/doctor_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final User user = snapshot.data!;

          // BEFORE: FirebaseFirestore.instance.collection('users').doc(user.uid).get()
          // NOW: through DatabaseService — screens/wrappers must not touch Firestore directly.

          // ─── FOR RAHMAH ─────────────────────────────────────────────────────
          // FIX: This is where we update the FCM token in Firestore every time
          // the user opens the app while logged in. FCM tokens can change at any
          // time (e.g. after app reinstall or data clear), so saving the latest
          // token here ensures the Cloud Function always has a valid token to
          // send notifications to. Without this call, the token in Firestore
          // would stay stale and notifications would eventually stop working.
          // ──────────────────────────────────────────────────────────────────
          DatabaseService().updateNotificationToken(user.uid);

          return FutureBuilder(
            future: DatabaseService().getUserById(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading user data',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          roleSnapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => AuthService().signOut(),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final userModel = roleSnapshot.data;
              if (userModel != null && userModel.role == 'admin') {
                return const AdminHomeScreen();
              }
              if (userModel != null && userModel.isDoctor) {
                // BUG FIX: BEFORE this check didn't exist here — only login_screen
                // checked isVerified. That meant on app restart (force-close + reopen),
                // an unverified doctor skipped straight to DoctorHomeScreen.
                // NOW: isVerified is enforced here too, closing that bypass.
                if (userModel.isVerified != true) {
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.hourglass_empty_rounded,
                              size: 80,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Account Pending Approval',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your doctor account is under review. You will be able to log in once an administrator approves it.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: () => AuthService().signOut(),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const DoctorHomeScreen();
              }

              return const PatientHomeScreen();
            },
          );
        }

        return const GuestHomeScreen();
      },
    );
  }
}
