import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';
import '../models/patient.dart';

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
      if (role == 'doctor') {
        DoctorModel newDoctor = DoctorModel(
          id: user.uid,
          name: name,
          specialty: specialty ?? 'General',
          location: location ?? 'Amman',
          imageUrl: '', // صورة فاضية مبدئياً
          rating: 0.0,
          about: 'New Doctor',
          isVerified: false, // أهم اشي: يدخل غير موثق
        );
        await firestore.collection('doctors').doc(user.uid).set(newDoctor.toMap());
      } 
      else {
        PatientModel newPatient = PatientModel(
          uid: user.uid,
          email: email,
          name: name,
          role: 'patient',
          profileImage: '',
        );
        await firestore.collection('users').doc(user.uid).set(newPatient.toMap());
      }

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