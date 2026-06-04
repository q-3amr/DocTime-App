import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/appointment.dart';
import '../utils/date_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db;

  DatabaseService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

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

  Future updateToken(String uid) async {
    await _db.collection("users").doc(uid).update({
      "pushToken": await _fcm.getToken(),
    });
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
    // Composite key: doctorId + millisecond timestamp → unique slot lock document
    final String appointmentKey =
        "${appointment.doctorId}_${appointment.appointmentDateTime.millisecondsSinceEpoch}";

    final txRef = _db.collection('booked_slots').doc(appointmentKey);

    try {
      return await _db.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(txRef);

        if (snapshot.exists) {
          // Slot already locked — abort to prevent double-booking
          return false;
        }

        // Atomically lock the slot
        transaction.set(txRef, {
          'bookedBy': appointment.patientId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Create the official appointment document inside the same transaction
        final newApptDoc = _db.collection('appointments').doc();
        transaction.set(newApptDoc, {
          'id': newApptDoc.id,
          'doctor_id': appointment.doctorId,
          'doctor_name': appointment.doctorName,
          'patient_id': appointment.patientId,
          'patient_name': appointment.patientName,
          'appointmentDateTime':
              Timestamp.fromDate(appointment.appointmentDateTime),
          'status': 'pending',
          'hasFeedback': false,
          'isReviewSeen': false,
        });

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<void> updateAppointmentStatus(
    String docId,
    String status, {
    String? cancelledBy, // 'patient' or 'doctor' — who triggered this change
  }) async {
    final Map<String, dynamic> data = {'status': status};
    if (cancelledBy != null) {
      data['cancelledBy'] = cancelledBy;
    }
    await _db.collection('appointments').doc(docId).update(data);
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
          "reviews_count": data['reviewCount'] ?? data['reviews_count'] ?? 0,
        };

        if (sortBy == "nearest") {
          doctorInfo["distance_in_km"] =
              double.parse((distanceInMeters / 1000).toStringAsFixed(1));
        }

        doctorsList.add(doctorInfo);
      }
      if (doctorsList.isEmpty) {
        if (sortBy == "nearest") {
          return jsonEncode({
            "success": false,
            "message":
                "There are doctors for this specialty, but NONE of them have their clinic location (GPS) saved in the database. Tell the user exactly: 'I cannot find the nearest doctor because no doctors in this specialty have registered their locations yet.'"
          });
        } else {
          return jsonEncode({
            "success": false,
            "message": "No verified doctors found for this specialty."
          });
        }
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
      DateTime parsedDate = DateTime.parse(date);
      String firestoreDate =
          "${parsedDate.year}-${parsedDate.month}-${parsedDate.day}";

      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .collection('availability')
          .doc(firestoreDate)
          .get();

      if (!docSnapshot.exists) {
        return jsonEncode({
          "success": true,
          "message": "The doctor has no working hours configured for today.",
          "available_slots": []
        });
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<dynamic> allSlots =
          data['slots'] ?? data['time_slots'] ?? data['available_slots'] ?? [];

      if (allSlots.isEmpty) {
        return jsonEncode({
          "success": true,
          "message": "The doctor has no working hours configured.",
          "available_slots": []
        });
      }

      // Fetch all pending/accepted appointments for this doctor and filter by date in-memory
      QuerySnapshot appointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .where('status', whereIn: ['pending', 'accepted']).get();

      // Collect booked time strings for the requested date
      List<String> bookedTimes = [];
      for (var doc in appointments.docs) {
        final apptData = doc.data() as Map<String, dynamic>;
        final rawDate = apptData['appointmentDateTime'];
        if (rawDate == null) continue;
        final DateTime apptDt = (rawDate as Timestamp).toDate();
        if (apptDt.year == parsedDate.year &&
            apptDt.month == parsedDate.month &&
            apptDt.day == parsedDate.day) {
          bookedTimes.add(formatTimeFromDateTime(apptDt));
        }
      }

      List<String> availableTimes = [];
      DateTime now = DateTime.now();

      bool isToday = parsedDate.year == now.year &&
          parsedDate.month == now.month &&
          parsedDate.day == now.day;

      for (String slot in allSlots) {
        if (!bookedTimes.contains(slot)) {
          if (isToday) {
            try {
              final parts = slot.split(' ');
              final timeParts = parts[0].split(':');
              int hour = int.parse(timeParts[0]);
              int minute = int.parse(timeParts[1]);

              if (parts.length > 1) {
                if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
                if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
              }

              final slotTime = DateTime(parsedDate.year, parsedDate.month,
                  parsedDate.day, hour, minute);
              if (slotTime.isBefore(now)) {
                continue;
              }
            } catch (_) {}
          }
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

  Future<String> bookAppointmentForAi(
      String doctorId, String date, String time) async {
    try {
      final String? patientId = FirebaseAuth.instance.currentUser?.uid;
      if (patientId == null) {
        return jsonEncode(
            {"error": "User is not logged in. Cannot book appointment."});
      }

      // Fetch patient name
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();
      String patientName = "Unknown";
      if (patientDoc.exists) {
        final pData = patientDoc.data() as Map<String, dynamic>;
        patientName = pData['name'] ?? pData['fullName'] ?? "Unknown";
      }

      // Fetch doctor name  ← FIX #1: was missing, causing "Doctor" to show
      DocumentSnapshot doctorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();
      String doctorName = "Doctor";
      if (doctorDoc.exists) {
        final dData = doctorDoc.data() as Map<String, dynamic>;
        doctorName = dData['name'] ?? dData['fullName'] ?? "Doctor";
      }

      DateTime parsedDate = DateTime.parse(date);

      // Parse the time slot (e.g. "10:00 PM") and combine with date
      // FIX #2: store as Timestamp so AppointmentModel.fromMap reads it correctly
      DateTime appointmentDateTime = parsedDate;
      try {
        final parts = time.trim().split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        if (parts.length > 1) {
          if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
          if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
        }
        appointmentDateTime = DateTime(
            parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
      } catch (_) {}

      // Conflict check: fetch all pending/accepted for this doctor and check for same DateTime
      QuerySnapshot checkConflict = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .where('status', whereIn: ['pending', 'accepted']).get();

      final bool alreadyBooked = checkConflict.docs.any((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final rawDate = d['appointmentDateTime'];
        if (rawDate == null) return false;
        final DateTime existing = (rawDate as Timestamp).toDate();
        return existing.year == appointmentDateTime.year &&
            existing.month == appointmentDateTime.month &&
            existing.day == appointmentDateTime.day &&
            existing.hour == appointmentDateTime.hour &&
            existing.minute == appointmentDateTime.minute;
      });

      if (alreadyBooked) {
        return jsonEncode({
          "success": false,
          "error":
              "CRITICAL: This exact time slot ($time) was just booked by someone else! Tell the user to choose another time from the available slots."
        });
      }

      // Store with the same structure as bookAppointmentSafely so the model reads correctly
      final String slotId =
          "appt_${doctorId}_${appointmentDateTime.millisecondsSinceEpoch}";
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(slotId)
          .set({
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'patient_id': patientId,
        'patient_name': patientName,
        'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
        'status': 'pending',
        'hasFeedback': false,
        'isReviewSeen': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      return jsonEncode({
        "success": true,
        "message":
            "Appointment successfully booked for $date at $time. Tell the user their appointment is now PENDING doctor approval."
      });
    } catch (e) {
      return jsonEncode(
          {"error": "Database error while booking the appointment: $e"});
    }
  }
}
