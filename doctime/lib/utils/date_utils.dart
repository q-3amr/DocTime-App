// ─────────────────────────────────────────────────────────────────────────────
// WHY THIS FILE EXISTS:
// These 5 date-related helpers were duplicated across 4+ screen files:
//   - schedule_screen.dart
//   - patient_home_screen.dart
//   - doctor_home_screen.dart
//   - doctor_requests_screen.dart
//   - manage_slots_screen.dart (had an unsafe version that could crash)
//
// Instead of each screen having its own private _parseDate / _isExpired /
// _formatDate methods, they all import from here.
// Fix a bug once → fixed everywhere. No more copy-paste drift.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// WHY: Firestore can store a date field as a Timestamp object OR as an
// ISO-8601 String depending on how it was written. This function safely handles
// BOTH types, so screens don't crash if the format is inconsistent.
// BEFORE: each screen had its own private _parseDate() — 4 identical copies.
// NOTE: manage_slots_screen.dart had a BUGGY version: (doc['date'] as Timestamp)
// which crashes when the date is stored as a String. This shared version is safe.
DateTime parseDate(dynamic dateData) {
  if (dateData is Timestamp) return dateData.toDate();
  if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
  return DateTime.now();
}

// WHY: An appointment is considered "expired" if it was scheduled more than
// 20 minutes ago (the patient is considered a no-show after 20 min).
// BEFORE: this exact logic was duplicated in schedule_screen and doctor_home_screen.
bool isExpiredAppointment(DateTime appointmentDate) {
  return DateTime.now().isAfter(
    appointmentDate.add(const Duration(minutes: 20)),
  );
}

// WHY: Converts a 24h DateTime into a 12h AM/PM string (e.g. "9:30 AM").
// Used whenever an appointment time slot needs to be shown to the user.
// BEFORE: this conversion was written inline in multiple screens each time
// a time string was needed, resulting in duplicated messy hour-math.
String formatTimeFromDateTime(DateTime date) {
  int hour =
      date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
  String minute = date.minute.toString().padLeft(2, '0');
  String amPm = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $amPm';
}

// WHY: Firestore availability subcollection uses dates as document IDs,
// e.g. "2025-6-15" (no padding). This format is the key used when
// saving / loading a doctor's slot availability for a specific day.
// Called by: doctor_details_screen, manage_slots_screen.
String formatDateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

// WHY: Padded date string for displaying to the user, e.g. "2025-06-15".
// Different from formatDateKey because the display version uses zero-padded
// month/day (06 instead of 6). Used in schedule cards and request cards.
// BEFORE: this formatting was inlined with .padLeft(2,'0') in multiple screens.
String formatDateDisplay(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
