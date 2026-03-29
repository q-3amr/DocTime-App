// ─────────────────────────────────────────────────────────────────────────────
// WHAT WAS CHANGED IN THIS FILE:
//
// 1. ERROR CODE TRANSLATION MOVED HERE (from login_screen):
//    login_screen had a 50-line switch(e.code) block to translate Firebase error
//    codes into user-friendly messages. That logic belongs in the service, not
//    the UI. Moved here into private const maps (_loginErrors, _signupErrors,
//    _resetErrors). Screens simply catch a String and show it.
//
// 2. sendPasswordResetEmail() ADDED:
//    Previously, ~60 lines of password-reset logic were inlined inside a
//    TextButton.onPressed callback in login_screen. Moved here as a proper
//    named method so it can be called cleanly and tested independently.
//
// 3. createdAt ADDED TO signUp():
//    signup_screen used to bypass this method and call Firebase directly,
//    adding 'createdAt: FieldValue.serverTimestamp()' in the process.
//    This method previously didn't add createdAt, so documents created via
//    the service were missing that field. Fixed: createdAt is now always added.
//
// 4. currentUser GETTER ADDED:
//    Screens needed access to the currently logged-in Firebase user.
//    Instead of them importing firebase_auth directly, they can use this getter.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// Centralises all Firebase Authentication operations.
/// RULE: Screens must NOT call FirebaseAuth.instance directly — all auth
/// operations go through this service.
class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Exposes the auth state stream so AuthWrapper can listen to login/logout events.
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Convenience getter — avoids screens importing firebase_auth just for currentUser.
  User? get currentUser => auth.currentUser;

  /// Signs the user in with email + password.
  ///
  /// BEFORE: login_screen called FirebaseAuth.instance.signInWithEmailAndPassword()
  /// directly, then had a 50-line switch(e.code) to translate errors.
  /// NOW: error translation happens here. Screen just catches a String.
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Translate the Firebase error code into a human-readable message.
      // The map lookup happens in _mapAuthError below.
      throw _mapAuthError(e.code, _loginErrors);
    }
  }

  /// Registers a new user in Firebase Auth AND saves their Firestore document.
  ///
  /// BEFORE: signup_screen bypassed this method entirely — it called Firebase
  /// directly and wrote a raw Map to Firestore. That created two separate code
  /// paths that could silently produce different Firestore documents.
  /// NOW: this is the ONLY registration path. signup_screen just calls this.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? specialty,
    String? location,
  }) async {
    try {
      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return;

      UserModel newUser = UserModel(
        id: user.uid,
        email: email,
        name: name,
        role: role,
        profileImage: '',
        specialty: role == 'doctor' ? (specialty ?? 'General') : null,
        location: role == 'doctor' ? (location ?? 'Amman') : null,
        rating: role == 'doctor' ? 0.0 : null,
        about: role == 'doctor' ? 'New Doctor' : null,
        // Doctors start as unverified — admin must approve them.
        isVerified: role == 'doctor' ? false : null,
      );

      final userMap = newUser.toMap();
      // BEFORE: signup_screen added createdAt but this method did not →
      // inconsistent documents. Now createdAt is always added here.
      userMap['createdAt'] = FieldValue.serverTimestamp();

      await firestore.collection('users').doc(user.uid).set(userMap);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e.code, _signupErrors);
    } catch (e) {
      throw 'Error saving user data: $e';
    }
  }

  /// Sends a password-reset email to the given address.
  ///
  /// BEFORE: ~60 lines of this logic (try/catch + switch on error codes) were
  /// inlined directly inside a TextButton.onPressed in login_screen.
  /// NOW: one clean method. login_screen calls it with one line.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e.code, _resetErrors);
    }
  }

  /// Signs the current user out.
  /// BEFORE: some screens called FirebaseAuth.instance.signOut() directly.
  Future<void> signOut() async => await auth.signOut();

  // ── Private helpers ───────────────────────────────────────────────────────

  // Looks up a Firebase error code in the provided map.
  // Falls back to the 'default' key if the code is not recognised.
  static String _mapAuthError(String code, Map<String, String> map) {
    return map[code] ?? map['default']!;
  }

  // Human-readable messages for each Firebase login error code.
  // BEFORE: these strings were scattered in a switch block inside login_screen.
  static const Map<String, String> _loginErrors = {
    'user-not-found': 'Incorrect email or password.',
    'wrong-password': 'Incorrect email or password.',
    'invalid-credential': 'Incorrect email or password.',
    'invalid-email': 'Invalid email format.',
    'network-request-failed': 'No internet connection.',
    'user-disabled': 'This user has been disabled.',
    'default': 'Login failed. Please try again.',
  };

  // Human-readable messages for registration errors.
  static const Map<String, String> _signupErrors = {
    'email-already-in-use': 'The email is already in use.',
    'weak-password': 'The password is too weak.',
    'invalid-email': 'Invalid email format.',
    'default': 'An error occurred during registration.',
  };

  // Human-readable messages for password-reset errors.
  static const Map<String, String> _resetErrors = {
    'invalid-email': 'Invalid email format.',
    'network-request-failed': 'No internet connection.',
    'user-not-found': 'No account found with this email.',
    'default': 'Failed to send reset email.',
  };
}
