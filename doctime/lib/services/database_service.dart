import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream يرجع قائمة الأطباء من كولكشن doctors
  Stream<List<DoctorModel>> streamDoctors() {
    return _db.collection('doctors').where('isVerified', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DoctorModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
  // (اختياري) دالة تضيف دكتور جديد
  Future<void> addDoctor(DoctorModel doctor) async {
    await _db.collection('doctors').add(doctor.toMap());
  }
}
