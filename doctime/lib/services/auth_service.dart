import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. مراقب حالة المستخدم (عشان نعرف إذا مسجل دخول ولا لأ)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 2. جلب المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // 3. تسجيل الدخول (Login)
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      print("Error in Login: ${e.message}");
      throw e; // بنرمي الخطأ عشان الواجهة تعرضه للمستخدم
    }
  }

  // 4. إنشاء حساب جديد (Register)
  Future<UserCredential?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      print("Error in Register: ${e.message}");
      throw e;
    }
  }

  // 5. تسجيل الخروج (Sign Out)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}