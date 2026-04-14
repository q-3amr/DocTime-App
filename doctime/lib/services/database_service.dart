// ─────────────────────────────────────────────────────────────────────────────
// WHY THIS FILE EXISTS / WHAT WAS ADDED:
//
// Central database access layer. ALL Firestore operations go through this class.
// Added logic for: Reviews, Notifications, and Automated Status Management.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user.dart';
import '../models/appointment.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<UserModel>> streamDoctors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
    return null;
  }

  Stream<UserModel?> streamUser(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
      return null;
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPOINTMENTS & REVIEWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// دالة تقديم التقييم: تُحدث الموعد وتفعل النقطة الزرقاء للدكتور
  Future<void> submitAppointmentFeedback({
    required String appointmentId,
    required String feedbackText,
    required double rating,
  }) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'hasFeedback': true,
      'feedback_text': feedbackText,
      'rating': rating,
      'isReviewSeen': false, // تفعيل التنبيه للدكتور
    });
  }

  /// دالة تصفير التنبيهات: تُستدعى عند دخول الدكتور لشاشة المراجعات
  Future<void> markAllReviewsAsSeen(String doctorId) async {
    final querySnapshot = await _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .where('hasFeedback', isEqualTo: true)
        .get();

    WriteBatch batch = _db.batch();
    bool hasUpdates = false;

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['isReviewSeen'] != true) {
        batch.update(doc.reference, {'isReviewSeen': true});
        hasUpdates = true;
      }
    }
    if (hasUpdates) await batch.commit();
  }

  Stream<QuerySnapshot> streamAppointmentsForDoctor(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .snapshots();
  }

  Stream<QuerySnapshot> streamPendingAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> streamAcceptedAppointmentsForPatient(String patientId) {
    return _db
        .collection('appointments')
        .where('patient_id', isEqualTo: patientId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  Stream<QuerySnapshot> streamUserAppointments(
    String userId, {
    required bool isDoctor,
  }) {
    return _db
        .collection('appointments')
        .where(isDoctor ? 'doctor_id' : 'patient_id', isEqualTo: userId)
        .snapshots();
  }

  Future<QuerySnapshot> getAppointmentsForDoctor(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .get();
  }

  /// الدالة التي كانت مفقودة في شاشة المواعيد
  Future<QuerySnapshot> getAppointmentsForDoctorByStatuses(
    String doctorId,
    List<String> statuses,
  ) {
    return _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .where('status', whereIn: statuses)
        .get();
  }

  /// دالة الحجز المحدثة: تضمن إضافة حقول التقييم والتنبيه افتراضياً
  Future<bool> bookAppointmentSafely(AppointmentModel appointment) async {
    try {
      String slotId =
          "appt_${appointment.doctorId}_${appointment.appointmentDateTime.millisecondsSinceEpoch}";
      DocumentReference apptRef = _db.collection('appointments').doc(slotId);

      return await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(apptRef);

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (data['status'] != 'cancelled' && data['status'] != 'rejected') {
            return false;
          }
        }

        final appointmentData = appointment.toMap();
        // إسناد القيم الافتراضية
        appointmentData['hasFeedback'] = false;
        appointmentData['isReviewSeen'] = false;

        transaction.set(apptRef, appointmentData);
        return true;
      });
    } catch (e) {
      print("Transaction Error: $e");
      return false;
    }
  }

  Future<void> updateAppointmentStatus(String docId, String status) async {
    await _db.collection('appointments').doc(docId).update({'status': status});
  }

  Future<void> deleteAppointment(String docId) async {
    await _db.collection('appointments').doc(docId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AVAILABILITY & CHATS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<DocumentSnapshot> getAvailability(String doctorId, String dateKey) {
    return _db
        .collection('users')
        .doc(doctorId)
        .collection('availability')
        .doc(dateKey)
        .get();
  }

  Future<void> saveSlots(
      String doctorId, String dateKey, List<String> slots) async {
    await _db
        .collection('users')
        .doc(doctorId)
        .collection('availability')
        .doc(dateKey)
        .set({'slots': slots}, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> streamChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> streamMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(
      String chatRoomId, Map<String, dynamic> messageData) async {
    await _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);
  }

  Future<void> updateChatRoom(
      String chatRoomId, Map<String, dynamic> data) async {
    await _db
        .collection('chats')
        .doc(chatRoomId)
        .set(data, SetOptions(merge: true));
  }

  Stream<List<UserModel>> streamUnverifiedDoctors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> approveDoctor(String doctorId) async {
    await _db.collection('users').doc(doctorId).update({'isVerified': true});
  }

  Future<void> updateNotificationToken(String userId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _db
            .collection('users')
            .doc(userId)
            .set({'pushToken': token}, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error updating notification token: $e");
    }
  }
}
