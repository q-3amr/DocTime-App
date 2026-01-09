import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // مراقب حالة المستخدم
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // المستخدم الحالي
  User? get currentUser => auth.currentUser;

  // تسجيل الدخول (زي ما هو)
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred";
    }
  }

  // --- التحديث القوي هون (التسجيل) ---
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'doctor' or 'patient'
    String? specialty, // اختياري (بس للدكتور)
    String? location,  // اختياري (بس للدكتور)
  }) async {
    try {
      // 1. إنشاء الحساب في Authentication (إيميل وباسوورد)
      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user == null) return;
      
      // Create unified UserModel
      UserModel newUser = UserModel(
        id: user.uid,
        email: email,
        name: name,
        role: role,
        profileImage: '',
        // Doctor-specific fields (only if role is doctor)
        specialty: role == 'doctor' ? (specialty ?? 'General') : null,
        location: role == 'doctor' ? (location ?? 'Amman') : null,
        rating: role == 'doctor' ? 0.0 : null,
        about: role == 'doctor' ? 'New Doctor' : null,
        isVerified: role == 'doctor' ? false : null, // أهم اشي: يدخل غير موثق
      );
      
      // Store all users in 'users' collection
      await firestore.collection('users').doc(user.uid).set(newUser.toMap());

    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Registration failed";
    } catch (e) {
      throw "Error saving user data: $e";
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await auth.signOut();
  }
}