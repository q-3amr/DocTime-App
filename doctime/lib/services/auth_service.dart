import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  User? get currentUser => auth.currentUser;

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred";
    }
  }

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
        isVerified: role == 'doctor' ? false : null,
      );

      await firestore.collection('users').doc(user.uid).set(newUser.toMap());
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Registration failed";
    } catch (e) {
      throw "Error saving user data: $e";
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
  }
}
