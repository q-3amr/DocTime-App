// ─────────────────────────────────────────────────────────────────────────────
// WHY THIS FILE EXISTS:
// Before this refactoring, the primary colour (0xFF407CE2) was declared as a
// local variable in EVERY screen file (~12 files):
//   final Color primaryBlue = const Color(0xFF407CE2);
// And the specialties list was copy-pasted in 3 separate files:
//   signup_screen.dart, profile_screen.dart, doctor_search_screen.dart
//
// This file centralises both so there is ONE place to change them.
// If you want to change the theme colour, change it here — it updates everywhere.
// If you want to add/remove a specialty, change it here — it updates everywhere.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// App-wide primary colour — was hardcoded locally in every single screen.
// Now imported from here, so a single change reflects across the whole app.
const Color kPrimaryBlue = Color(0xFF407CE2);

// Shared specialty list — was copy-pasted in signup_screen, profile_screen,
// and doctor_search_screen. Three copies = three places to update when you add
// a specialty. Now it lives here, one place only.
const List<String> kSpecialties = [
  'General Medicine',
  'Dentistry',
  'Cardiology',
  'Psychiatry',
  'Nutrition',
  'Urology',
  'Dermatology',
  'Gynecology & Obstetrics',
  'Orthopedics',
  'Pediatrics',
  'Internal Medicine',
  'Ophthalmology',
  'Neurology',
  'Gastroenterology',
  'ENT',
  'Pulmonology',
  'Endocrinology',
  'Otolaryngology'
];
