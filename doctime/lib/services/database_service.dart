// ─────────────────────────────────────────────────────────────────────────────
// WHY THIS FILE EXISTS / WHAT WAS ADDED:
//
// This service existed before but had only 3 stub methods (streamDoctors,
// addDoctor, getUserById). Despite having a service layer, every screen still
// called FirebaseFirestore.instance directly — making the service pointless.
//
// RULE: NO screen should import 'package:cloud_firestore/cloud_firestore.dart'
// for data access. All Firestore operations go through this class.
//
// Added 16 new methods to cover: Users, Appointments, Availability, Chats.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/appointment.dart';

/// Central database access layer.
/// Screens call methods here — they never touch FirebaseFirestore directly.
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns a live stream of all verified doctors as typed [UserModel] objects.
  /// Used by: doctor_search_screen (was a raw QuerySnapshot before).
  /// Returning List<UserModel> means screens get type safety — no raw Map casting.
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

  /// One-time fetch of a user by UID. Returns null if the document doesn't exist.
  /// Used by: auth_wrapper, login_screen, doctor_details_screen, profile_screen,
  ///          chats_list_screen, doctor_home_screen.
  /// BEFORE: each of those called FirebaseFirestore.instance.collection('users')
  ///         .doc(uid).get() separately — now one method, one place.
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
    return null;
  }

  /// Live stream of a single user document as a [UserModel].
  /// Used by: patient_home_screen — to keep the greeting name up to date.
  /// BEFORE: was a StreamBuilder<DocumentSnapshot> with raw map['name'] access.
  Stream<UserModel?> streamUser(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
      return null;
    });
  }

  /// Updates specific fields on a user document (partial update, not full replace).
  /// Used by: profile_screen — when the user saves their profile changes.
  /// BEFORE: profile_screen called Firestore.update() directly.
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  /// Permanently deletes a user's Firestore document.
  /// Used by: profile_screen — when the user deletes their account.
  /// BEFORE: profile_screen called Firestore.delete() directly.
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPOINTMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of ALL appointments for a doctor (any status).
  /// Used by: doctor_home_screen — to count pending/upcoming/completed for stats.
  /// BEFORE: doctor_home_screen had a direct Firestore stream in its build method.
  Stream<QuerySnapshot> streamAppointmentsForDoctor(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .snapshots();
  }

  /// Live stream of PENDING appointment requests for a doctor.
  /// Used by: doctor_requests_screen — shows the pending request list.
  /// BEFORE: doctor_requests_screen had a direct Firestore stream in its build.
  Stream<QuerySnapshot> streamPendingAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Live stream of ACCEPTED appointments for a patient (upcoming only).
  /// Used by: patient_home_screen — for the upcoming appointment countdown banner.
  /// BEFORE: patient_home_screen had a direct Firestore stream in its build.
  Stream<QuerySnapshot> streamAcceptedAppointmentsForPatient(String patientId) {
    return _db
        .collection('appointments')
        .where('patient_id', isEqualTo: patientId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  /// Live stream of appointments for EITHER a doctor OR a patient.
  /// Used by: schedule_screen — which shows both doctor and patient schedules.
  /// The isDoctor flag switches the Firestore field being filtered.
  /// BEFORE: schedule_screen had a direct Firestore stream and also had to
  ///         fetch the role separately just to know which field to filter by.
  Stream<QuerySnapshot> streamUserAppointments(
    String userId, {
    required bool isDoctor,
  }) {
    return _db
        .collection('appointments')
        .where(isDoctor ? 'doctor_id' : 'patient_id', isEqualTo: userId)
        .snapshots();
  }

  /// One-time fetch of all appointments for a doctor.
  /// Used by: doctor_details_screen — to check which time slots are already taken
  ///          before showing available slots to the patient.
  /// BEFORE: doctor_details_screen called Firestore.get() directly.
  Future<QuerySnapshot> getAppointmentsForDoctor(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .get();
  }

  /// One-time fetch filtered by multiple statuses (uses Firestore whereIn).
  /// Used by: manage_slots_screen — to find which time slots are already booked
  ///          (pending or accepted) so it can hide them from the slot list.
  /// BEFORE: manage_slots_screen called Firestore directly with whereIn.
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

  /// Creates a new appointment document in Firestore.
  /// Used by: doctor_details_screen — when a patient books an appointment.
  /// BEFORE: doctor_details_screen called Firestore.add() directly.
  /// دالة حجز آمنة بتستخدم (Transactions) لمنع الـ Race Condition.
  /// هاي الدالة بتضمن إنه مستحيل مريضين يحجزوا نفس الموعد بنفس اللحظة.
  Future<bool> bookAppointmentSafely(AppointmentModel appointment) async {
    try {
      // 1. صناعة ID ذكي وموحد:
      // بدل ما الفايربيز يعطينا ID عشوائي، بنعمل ID ثابت بيعتمد على (ID الدكتور + وقت الموعد).
      // هيك الداتابيز بتعرف إنه هاد "موعد واحد" ومستحيل تعمل منه نسختين.
      String slotId =
          "appt_${appointment.doctorId}_${appointment.appointmentDateTime.millisecondsSinceEpoch}";

      // 2. تجهيز المرجع (Reference):
      // بنحدد مسار الدوكيومنت بالداتابيز اللي رح نشتغل عليه.
      DocumentReference apptRef = _db.collection('appointments').doc(slotId);

      // 3. تشغيل القفل (runTransaction):
      // الترانزاكشن بيقفل هاد الدوكيومنت بالسيرفر، وبمنع أي حدا ثاني يعدل عليه بنفس اللحظة.
      return await _db.runTransaction((transaction) async {
        // 4. قراءة الدوكيومنت:
        // بنقرأ الموعد من السيرفر عشان نتأكد إذا في مريض ثاني كبس زر الحجز قبلنا بملي ثانية.
        DocumentSnapshot snapshot = await transaction.get(apptRef);

        // 5. فحص حالة الموعد:
        // إذا الدوكيومنت موجود، يعني في حدا حجزه!
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          // نتأكد إنه الموعد مش "ملغي" ولا "مرفوض" (لأنه لو ملغي بنقدر نرجع نحجزه).
          if (data['status'] != 'cancelled' && data['status'] != 'rejected') {
            // الموعد محجوز فعلياً! بنرفض العملية وبنرجع false.
            return false;
          }
        }

        // 6. الحجز الفعلي:
        // إذا الموعد فاضي أو كان ملغي، بنحط الداتا تبعت المريض باستخدام دالة toMap() تبعت الموديل.
        transaction.set(apptRef, appointment.toMap());

        // بنرجع true يعني الحجز تم بنجاح بدون أي تضارب.
        return true;
      });
    } catch (e) {
      // إذا صار أي إيرور بالاتصال، بنطبع الإيرور وبنرجع false عشان الواجهة تتصرف.
      print("Transaction Error: $e");
      return false;
    }
  }

  /// Updates only the 'status' field of an appointment.
  /// Used by: schedule_screen (cancel/complete), doctor_requests_screen (accept/decline).
  /// BEFORE: each of those screens called Firestore.doc().update() directly —
  ///         the same one-liner duplicated in 4+ places.
  Future<void> updateAppointmentStatus(String docId, String status) async {
    await _db.collection('appointments').doc(docId).update({'status': status});
  }

  /// Permanently deletes an appointment document.
  /// Used by: schedule_screen — when the user removes a record from history.
  /// BEFORE: schedule_screen called Firestore.doc().delete() directly.
  Future<void> deleteAppointment(String docId) async {
    await _db.collection('appointments').doc(docId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AVAILABILITY (doctor slots)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches a doctor's availability document for a specific date.
  /// The date is stored as a document ID using formatDateKey() — e.g. "2025-6-15".
  /// Used by: doctor_details_screen (to show available slots to patient),
  ///          manage_slots_screen (to load the doctor's own saved slots).
  /// BEFORE: both screens had the full Firestore path inline in their code.
  Future<DocumentSnapshot> getAvailability(
    String doctorId,
    String dateKey,
  ) {
    return _db
        .collection('users')
        .doc(doctorId)
        .collection('availability')
        .doc(dateKey)
        .get();
  }

  /// Saves (or updates) the list of time slots for a doctor on a specific date.
  /// Uses merge:true so existing fields on the document are not overwritten.
  /// Used by: manage_slots_screen — when the doctor adds/removes a time slot.
  /// BEFORE: manage_slots_screen called the full Firestore path with .set() directly.
  Future<void> saveSlots(
    String doctorId,
    String dateKey,
    List<String> slots,
  ) async {
    await _db
        .collection('users')
        .doc(doctorId)
        .collection('availability')
        .doc(dateKey)
        .set({'slots': slots}, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHATS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of all chat rooms where the user is a participant.
  /// Used by: chats_list_screen — to show the list of conversations.
  /// BEFORE: chats_list_screen had the Firestore stream inline in its build method.
  Stream<QuerySnapshot> streamChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  /// Live stream of messages in a chat room, newest-first.
  /// Used by: chat_screen — to display the message list.
  /// BEFORE: chat_screen stored a FirebaseFirestore instance field and called it directly.
  Stream<QuerySnapshot> streamMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Adds a new message document to a chat room's messages sub-collection.
  /// Used by: chat_screen — when the user sends a message.
  /// BEFORE: chat_screen called Firestore directly in _sendMessage().
  Future<void> sendMessage(
    String chatRoomId,
    Map<String, dynamic> messageData,
  ) async {
    await _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);
  }

  /// Creates or updates the top-level chat room document (participants, lastMessage).
  /// Uses merge:true to avoid overwriting data that wasn't passed in.
  /// Used by: chat_screen — called after every message send to update lastMessage.
  /// BEFORE: chat_screen called Firestore .set() with merge directly.
  Future<void> updateChatRoom(
    String chatRoomId,
    Map<String, dynamic> data,
  ) async {
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> approveDoctor(String doctorId) async {
    await _db.collection('users').doc(doctorId).update({'isVerified': true});
  }
}
