import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/action_button.dart';
import '../common/schedule_screen.dart';
import '../common/profile_screen.dart';
import '../common/chats_list_screen.dart';
import '../patient/doctor_search_screen.dart';
import 'doctor_requests_screen.dart';
import 'manage_slots_screen.dart';
import 'doctor_reviews_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});
  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final List<Widget> pages = [
      const DoctorDashboard(),
      const ScheduleScreen(isDoctor: true),
      const DoctorRequestsScreen(),
      const ProfileScreen()
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border(top: BorderSide(color: Colors.grey.shade100, width: 1))),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: kPrimaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded), label: 'Schedule'),
            BottomNavigationBarItem(
              icon: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('doctor_id', isEqualTo: uid)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  int count = snapshot.data?.docs.length ?? 0;
                  return _buildBadgeIcon(
                      Icons.notifications_none_rounded, count);
                },
              ),
              label: 'Requests',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon, int count) {
    return Stack(clipBehavior: Clip.none, children: [
      Icon(icon),
      if (count > 0)
        Positioned(
            right: -6,
            top: -6,
            child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center))),
    ]);
  }
}

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final db = DatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;
  StreamSubscription? _universalFeedbackListener;
  final TextEditingController _feedbackController = TextEditingController();

  bool _isPopupOpen = false;

  @override
  void initState() {
    super.initState();
    _startUniversalFeedbackListener();
  }

  @override
  void dispose() {
    _universalFeedbackListener?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  void _startUniversalFeedbackListener() {
    if (user?.uid == null) return;

    _universalFeedbackListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('patient_id', isEqualTo: user!.uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data['hasFeedback'] != true && !_isPopupOpen) {
          bool isRecent = true;
          try {
            // فحص التاريخ بأمان بدون استخدام متغيرات غير ضرورية
            if (data['date'] is Timestamp) {
              Timestamp ts = data['date'];
              // إذا الموعد أقدم من 3 أيام لا تظهره (لتقليل الإزعاج)
              if (DateTime.now().difference(ts.toDate()).inDays > 3) {
                isRecent = false;
              }
            }
          } catch (e) {
            debugPrint("Date error: $e");
          }

          if (isRecent) {
            setState(() => _isPopupOpen = true);
            _showFeedbackPopup(context, doc.id);
            break;
          }
        }
      }
    });
  }

  void _showFeedbackPopup(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded,
                      color: Colors.amber, size: 50),
                  const SizedBox(height: 10),
                  const Text('Rate your experience',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber.withOpacity(0.2)),
                    ),
                    child: const Column(
                      children: [
                        Text("⭐⭐⭐⭐⭐", style: TextStyle(fontSize: 24)),
                        SizedBox(height: 5),
                        Text("Qusai: Add Stars Logic Here",
                            style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Write your feedback...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('appointments')
                            .doc(appointmentId)
                            .update({'hasFeedback': true});

                        await db.submitAppointmentFeedback(
                          appointmentId: appointmentId,
                          feedbackText: _feedbackController.text,
                          rating: 5.0,
                        );

                        _feedbackController.clear();
                        if (mounted) setState(() => _isPopupOpen = false);
                        Navigator.pop(context);
                      },
                      child: const Text('Submit',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('appointments')
                      .doc(appointmentId)
                      .update({'hasFeedback': true});

                  if (mounted) setState(() => _isPopupOpen = false);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kPrimaryBlue.withOpacity(0.15), Colors.white],
                      stops: const [0.0, 0.4]))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Welcome back,',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16)),
                              FutureBuilder(
                                  future: db.getUserById(user?.uid ?? ''),
                                  builder: (context, snapshot) {
                                    return Text(
                                        'Dr. ${snapshot.data?.name ?? 'Doctor'}',
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900));
                                  }),
                            ])),
                        CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFE0E7FF),
                            child: Icon(Icons.person,
                                color: kPrimaryBlue, size: 28)),
                      ]),
                  const SizedBox(height: 30),
                  StreamBuilder<dynamic>(
                    stream: user?.uid != null
                        ? db.streamAppointmentsForDoctor(user!.uid)
                        : null,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;

                      final bool hasNewReview = docs.any((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['hasFeedback'] == true &&
                            data['isReviewSeen'] != true;
                      });

                      final int upcoming = docs
                          .where((d) =>
                              d['status'] == 'accepted' &&
                              !isExpiredAppointment(parseDate(d['date'])))
                          .length;
                      final int pending =
                          docs.where((d) => d['status'] == 'pending').length;

                      return Column(
                        children: [
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: kPrimaryBlue,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                        color: kPrimaryBlue.withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8))
                                  ]),
                              child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      const Text('Pending Requests',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      Text('$pending Pending',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900))
                                    ])),
                                const Icon(Icons.notifications_active,
                                    color: Colors.white, size: 30)
                              ])),
                          const SizedBox(height: 25),
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Quick Actions',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(height: 15),
/**************************************************/
                          Row(
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1.1,
                                  child: ActionButton(
                                      icon: const Icon(Icons.calendar_today_rounded,
                                          color: Colors.orange, size: 28),
                                      title: '$upcoming Upcoming',
                                      color: Colors.orange,
                                      isSquare: true,
                                      onTap: () {}),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1.1,
                                  child: ActionButton(
                                      icon: const Icon(
                                          Icons.access_time_filled_rounded,
                                          color: Colors.teal,
                                          size: 28),
                                      title: 'Manage Slots',
                                      color: Colors.teal,
                                      isSquare: true,
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (c) =>
                                                  const ManageSlotsScreen()))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Column(
                            children: [
                              ActionButton(
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.star_rate_rounded,
                                        color: Colors.amber, size: 32),
                                    if (hasNewReview)
                                      Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2)))),
                                  ],
                                ),
                                title: 'Reviews',
                                color: Colors.amber,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) =>
                                            const DoctorReviewsScreen())),
                              ),
                              const SizedBox(height: 15),
                              ActionButton(
                                icon: const Icon(Icons.chat_bubble_rounded,
                                    color: Colors.indigo, size: 28),
                                title: 'My Chats',
                                color: Colors.indigo,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) =>
                                            const ChatsListScreen())),
                              ),
                              const SizedBox(height: 15),
                              ActionButton(
                                  icon: const Icon(Icons.person_search_rounded,
                                      color: Colors.blue, size: 28),
                                  title: 'Find Doctor',
                                  color: Colors.blue,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (c) =>
                                              const DoctorSearchScreen()))),
                            ],
                          ),
/**************************************************/
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
