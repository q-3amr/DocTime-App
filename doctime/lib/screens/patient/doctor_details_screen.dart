// ─────────────────────────────────────────────────────────────────────────────
// WHAT WAS CHANGED IN THIS FILE:
//
// 1. AVAILABILITY READ REPLACED:
//    BEFORE: FirebaseFirestore.instance.collection('users').doc(doctorId)
//            .collection('availability').doc(dateKey).get() — directly in UI.
//    NOW: _db.getAvailability(doctorId, dateKey) — through DatabaseService.
//
// 2. APPOINTMENTS READ REPLACED:
//    BEFORE: FirebaseFirestore.instance.collection('appointments')
//            .where('doctor_id', isEqualTo: doctorId).get() — in UI.
//    NOW: _db.getAppointmentsForDoctor(doctorId)
//
// 3. PATIENT NAME FETCH REPLACED + TYPE IMPROVED:
//    BEFORE: FirebaseFirestore.instance.collection('users').doc(uid).get()
//    then raw DocumentSnapshot['name'] casting.
//    NOW: _db.getUserById(uid) returns UserModel? — access .name directly.
//
// 4. APPOINTMENT BOOKING REPLACED:
//    BEFORE: FirebaseFirestore.instance.collection('appointments').add({...}) in UI.
//    NOW: _db.addAppointment({...})
//
// 5. DATE HELPERS FROM SHARED UTILS:
//    BEFORE: inline date math for time string formatting.
//    NOW: formatDateKey(), formatTimeFromDateTime() from date_utils.dart.
//
// 6. RATING — INTENTIONALLY HARDCODED DUMMY:
//    '4.8 (120 Reviews)' — will be replaced with real data in a future update.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart'; // replaces all direct Firestore DB calls
import '../../utils/constants.dart'; // kPrimaryBlue — was a local variable before
import '../../utils/date_utils.dart'; // formatDateKey, formatTimeFromDateTime, parseDate
import '../common/chat_screen.dart';
import '../auth/login_screen.dart';
import '../../models/appointment.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String? doctorId;

  const DoctorDetailsScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    this.doctorId,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final _db = DatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _generateSlotsForDate(_selectedDate);
  }

  void _generateSlotsForDate(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
    });

    final dateKey = formatDateKey(date);

    final availabilityDoc = await _db.getAvailability(
      widget.doctorId ?? '',
      dateKey,
    );

    if (!availabilityDoc.exists || availabilityDoc['slots'] == null) {
      if (mounted) {
        setState(() {
          _availableSlots = [];
          _isLoadingSlots = false;
        });
      }
      return;
    }

    final List<String> doctorSlots = List<String>.from(
      availabilityDoc['slots'],
    );

    final appointmentsSnap = await _db.getAppointmentsForDoctor(
      widget.doctorId ?? '',
    );

    final Set<String> takenTimes = {};
    for (var doc in appointmentsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final DateTime apptDate = parseDate(data['date']);

      if (apptDate.year == date.year &&
          apptDate.month == date.month &&
          apptDate.day == date.day) {
        if (data['status'] != 'cancelled' && data['status'] != 'rejected') {
          takenTimes.add(formatTimeFromDateTime(apptDate));
        }
      }
    }

    final available =
        doctorSlots.where((s) => !takenTimes.contains(s)).toList();

    if (mounted) {
      setState(() {
        _availableSlots = available;
        _isLoadingSlots = false;
      });
    }
  }

  void _bookAppointment() async {
    if (user == null) {
      _showLoginDialog();
      return;
    }
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot first!')),
      );
      return;
    }

    // Parse selected time-slot string back to a DateTime.
    final parts = _selectedTimeSlot!.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    if (parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts[1] == 'AM' && hour == 12) hour = 0;

    final finalDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    try {
      final patient = await _db.getUserById(user!.uid);
      final patientName = patient?.name ?? 'Unknown';

      // 1. استخدام الموديل النظيف بدل الـ Map العشوائي المفرط
      final newAppointment = AppointmentModel(
        id: '', // رح نعمله ID ذكي بالسيرفس عشان الترانزاكشن
        doctorId: widget.doctorId ?? '',
        doctorName: widget.doctorName,
        patientId: user!.uid,
        patientName: patientName,
        appointmentDateTime: finalDate,
        status: 'pending',
      );

      // 2. استدعاء دالة القفل الآمنة اللي بترجع true أو false
      final success = await _db.bookAppointmentSafely(newAppointment);

      if (mounted) {
        if (success) {
          // الحجز تم بدون مشاكل وتضارب
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request Sent! Wait for approval.')),
          );
          Navigator.pop(context);
        } else {
          // الموعد انحجز لمريض ثاني بنفس اللحظة! بنرفض الطلب وبنحدث الواجهة
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Sorry, this slot was just booked by someone else!'),
              backgroundColor: Colors.red,
            ),
          );
          _generateSlotsForDate(_selectedDate);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'Please login to book an appointment. You can browse doctors '
          'without an account, but booking requires login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: kPrimaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: kPrimaryBlue.withOpacity(0.8),
                child: const Icon(Icons.person, size: 100, color: Colors.white),
              ),
              title: Text(
                'Dr. ${widget.doctorName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.specialty,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      const Text(
                        '4.8 (120 Reviews)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Select Date',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        final day = DateTime.now().add(Duration(days: index));
                        final isSelected = day.day == _selectedDate.day &&
                            day.month == _selectedDate.month;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedDate = day);
                            _generateSlotsForDate(day);
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? kPrimaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? kPrimaryBlue
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  [
                                    'Sun',
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                  ][day.weekday % 7],
                                  style: TextStyle(
                                    color:
                                        isSelected ? Colors.white : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Available Time Slots',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _isLoadingSlots
                      ? const Center(child: CircularProgressIndicator())
                      : _availableSlots.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No slots available for this day',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _availableSlots.map((slot) {
                                final isSelected = _selectedTimeSlot == slot;
                                return ChoiceChip(
                                  label: Text(slot),
                                  selected: isSelected,
                                  selectedColor: kPrimaryBlue,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  onSelected: (val) => setState(
                                    () => _selectedTimeSlot = val ? slot : null,
                                  ),
                                );
                              }).toList(),
                            ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: kPrimaryBlue,
                ),
                onPressed: () {
                  if (user == null) {
                    _showLoginDialog();
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ChatScreen(
                        receiverId: widget.doctorId!,
                        receiverName: widget.doctorName,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _selectedTimeSlot == null ? null : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
