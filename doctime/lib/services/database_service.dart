import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/appointment.dart';
import 'package:geolocator/geolocator.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<void> submitAppointmentFeedback({
    required String appointmentId,
    required String feedbackText,
    required double rating,
  }) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'hasFeedback': true,
      'feedback_text': feedbackText,
      'rating': rating,
      'isReviewSeen': false,
    });
  }

  Future<void> updateDoctorAggregateRating(String doctorId) async {
    final snapshot = await _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .where('hasFeedback', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) return;

    final ratings = snapshot.docs
        .map((d) => d.data()['rating'])
        .where((r) => r != null)
        .map((r) => (r as num).toDouble())
        .toList();

    if (ratings.isEmpty) return;

    final double average = ratings.reduce((a, b) => a + b) / ratings.length;

    await _db.collection('users').doc(doctorId).update({
      'rating': double.parse(average.toStringAsFixed(1)),
      'reviewCount': ratings.length,
    });
  }

  Stream<QuerySnapshot> streamReviewsForDoctor(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .where('hasFeedback', isEqualTo: true)
        .snapshots();
  }

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

  Future<bool> bookAppointmentSafely(AppointmentModel appointment) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

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

        appointmentData['hasFeedback'] = false;
        appointmentData['isReviewSeen'] = false;
        appointmentData['patientFcmToken'] = token;

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
        debugPrint("FCM token updated in Firestore for user: $userId");
      }
    } catch (e) {
      debugPrint("Error updating notification token: $e");
    }
  }

  Future<String> searchDoctorsForAi(String specialty, String sortBy,
      {double? userLat, double? userLng}) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('specialty', isEqualTo: specialty);

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return jsonEncode({
          "success": false,
          "message": "No doctors found for this specialty in the database."
        });
      }

      List<Map<String, dynamic>> doctorsList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['isVerified'] != true) continue;

        double docLat = (data['latitude'] ?? data['lat'] ?? 0.0).toDouble();
        double docLng = (data['longitude'] ?? data['lng'] ?? 0.0).toDouble();
        double distanceInMeters = 0.0;

        if (sortBy == "nearest" && userLat != null && userLng != null) {
          if (docLat == 0.0 && docLng == 0.0) continue;
          distanceInMeters =
              Geolocator.distanceBetween(userLat, userLng, docLat, docLng);
        }

        var rawRating = data['rating'] ??
            data['rating'] ??
            data['Rating'] ??
            data['rate'] ??
            0.0;
        double doctorRating = double.tryParse(rawRating.toString()) ?? 0.0;

        Map<String, dynamic> doctorInfo = {
          "doctor_id": doc.id,
          "name": data['name'] ?? "Unknown",
          "rating": doctorRating,
          "reviews_count": data['reviews_count'] ?? data['Reviews_count'] ?? 0,
        };

        if (sortBy == "nearest") {
          doctorInfo["distance_in_km"] =
              double.parse((distanceInMeters / 1000).toStringAsFixed(1));
        }

        doctorsList.add(doctorInfo);
      }
      if (doctorsList.isEmpty) {
        return jsonEncode({
          "success": false,
          "message":
              "No verified doctors found with valid locations for this specialty."
        });
      }
      if (sortBy == "rating") {
        doctorsList
            .sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
      } else if (sortBy == "nearest") {
        doctorsList.sort((a, b) => (a['distance_in_km'] as double)
            .compareTo(b['distance_in_km'] as double));
      }

      return jsonEncode(
          {"success": true, "doctors_found": doctorsList.take(4).toList()});
    } catch (e) {
      return jsonEncode({"error": "Database error occurred: $e"});
    }
  }

  Future<String> getDoctorAvailabilityForAi(
      String doctorId, String date) async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();
      if (!docSnapshot.exists) {
        return jsonEncode({"error": "Doctor not found in the database."});
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<dynamic> allSlots = data['available_slots'] ?? [];

      if (allSlots.isEmpty) {
        return jsonEncode({
          "success": true,
          "message": "The doctor has no working hours configured.",
          "available_slots": []
        });
      }

      QuerySnapshot appointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .where('date', isEqualTo: date)
          .where('status', whereIn: ['pending', 'accepted']).get();

      List<String> bookedTimes =
          appointments.docs.map((doc) => doc['time'] as String).toList();

      List<String> availableTimes = [];
      for (String slot in allSlots) {
        if (!bookedTimes.contains(slot)) {
          availableTimes.add(slot);
        }
      }

      return jsonEncode(
          {"success": true, "date": date, "available_slots": availableTimes});
    } catch (e) {
      return jsonEncode(
          {"error": "Database error while fetching availability: $e"});
    }
  }
}
