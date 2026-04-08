// ─────────────────────────────────────────────────────────────────────────────
// WHAT WAS FIXED IN THIS FILE:
//
// 1. FIELD NAME MISMATCH (was a silent bug):
//    The old toMap() used camelCase keys: 'doctorId', 'patientId', 'dateTime'.
//    But every screen that wrote appointments used snake_case: 'doctor_id',
//    'patient_id', 'date' — which is what Firestore actually stores.
//    If fromMap/toMap had ever been used, data would have been unreadable.
//    Fixed: all keys now match Firestore exactly.
//
// 2. MISSING FIELDS:
//    The old model was missing 'doctor_name' and the date was named 'dateTime'
//    (not 'date'). Screens write both of these fields when booking.
//    Fixed: added doctorName field; date key renamed to 'date'.
//
// 3. DATE PARSING:
//    Now uses parseDate() from date_utils.dart instead of duplicating the
//    Timestamp → DateTime conversion here.
//
// 4. DEAD CODE:
//    This model existed but was never used anywhere in the app — all screens
//    read/wrote appointments as raw Map<String, dynamic>. The model is now
//    correct and ready to be used when needed.
// ─────────────────────────────────────────────────────────────────────────────

// Uses shared parseDate() instead of duplicating Timestamp/String handling here.
import '../utils/date_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single document in the Firestore `appointments` collection.
/// Field names in fromMap/toMap match the snake_case keys stored in Firestore.
class AppointmentModel {
  final String id;
  final String doctorId;
  final String doctorName; // Added — was missing from the original model.
  final String patientId;
  final String patientName;
  final DateTime appointmentDateTime;
  final String status;
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.appointmentDateTime,
    required this.status,
    this.notes,
  });

  factory AppointmentModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return AppointmentModel(
      id: documentId,
      // BEFORE: map['doctorId'] — did NOT match Firestore which stores 'doctor_id'
      doctorId: map['doctor_id'] ?? '',
      // BEFORE: field did not exist in old model at all
      doctorName: map['doctor_name'] ?? '',
      // BEFORE: map['patientId'] — did NOT match Firestore 'patient_id'
      patientId: map['patient_id'] ?? '',
      patientName: map['patient_name'] ?? 'Unknown',
      // BEFORE: map['dateTime'] — did NOT match Firestore 'date'
      // Uses shared parseDate() to safely handle Timestamp OR String formats.
      appointmentDateTime: parseDate(map['date']),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // All keys now match what screens actually write to Firestore.
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'patient_id': patientId,
      'patient_name': patientName,
      'date': Timestamp.fromDate(appointmentDateTime),
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  // Utility to create a modified copy without mutating the original.
  AppointmentModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? patientId,
    String? patientName,
    DateTime? appointmentDateTime,
    String? status,
    String? notes,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      appointmentDateTime: appointmentDateTime ?? this.appointmentDateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
