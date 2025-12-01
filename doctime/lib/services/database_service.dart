import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // اسم المجموعة في الداتابيس
  final String _doctorsCollection = 'doctors';

  // 1. لإضافة دكتور جديد (للتجربة أو للمستقبل)
  Future<void> addDoctor(DoctorModel doctor) async {
    try {
      // بنستخدم الـ id تبع الدكتور كاسم للملف
      await _firestore.collection(_doctorsCollection).doc(doctor.id).set(doctor.toMap());
      print("Doctor Added Successfully!");
    } catch (e) {
      print("Error adding doctor: $e");
    }
  }

  // 2. لجلب قائمة الدكاترة (بس الموثقين isVerified == true)
  Stream<List<DoctorModel>> getVerifiedDoctors() {
    return _firestore
        .collection(_doctorsCollection)
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DoctorModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}