import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';
import '../models/patient.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // مراقب حالة المستخدم
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // تسجيل الدخول (زي ما هو)
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user == null) return;

      // 2. حفظ البيانات الإضافية في Firestore حسب الدور
      if (role == 'doctor') {
        // إذا دكتور: بنعمل موديل وبنحفظه في doctors collection
        DoctorModel newDoctor = DoctorModel(
          id: user.uid, // نستخدم نفس الـ ID تبع الـ Auth
          name: name,
          specialty: specialty ?? 'General',
          location: location ?? 'Amman',
          imageUrl: '', // صورة فاضية مبدئياً
          rating: 0.0,
          about: 'New Doctor',
          isVerified: false, // أهم اشي: يدخل غير موثق
        );

        // الحفظ في كولكشن doctors
        await _firestore.collection('doctors').doc(user.uid).set(newDoctor.toMap());
      
      } else {
        // --- ✅ التعديل الجديد (كود المريض) ---
        
        // بنعمل اوبجيكت من كلاس المريض
        PatientModel newPatient = PatientModel(
          uid: user.uid,
          email: email,
          name: name,
          role: 'patient',
          profileImage: '', // بنبعثها فاضية بالبداية
        );

        // بنحفظها بالداتابيس
        await _firestore.collection('users').doc(user.uid).set(newPatient.toMap());
      }

    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Registration failed";
    } catch (e) {
      throw "Error saving user data: $e";
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }
}