// ─────────────────────────────────────────────────────────────────────────────
// WHAT WAS CHANGED IN THIS FILE:
//
// 1. DIRECT FIRESTORE CALLS REPLACED:
//    BEFORE: StreamBuilder<DocumentSnapshot> from FirebaseFirestore.instance directly
//    for the user name, and another direct stream for appointments.
//    NOW: DatabaseService().streamUser(uid) — typed Stream<UserModel?>, no Map casting.
//         DatabaseService().streamAcceptedAppointmentsForPatient(uid) for the banner.
//
// 2. ActionButton WIDGET USED:
//    BEFORE: had a private _buildActionBtn(icon, title, color, onTap) method.
//    NOW: uses shared ActionButton from widgets/action_button.dart.
//    (same widget was duplicated in doctor_home_screen and guest_home_screen).
//
// 3. ScheduleScreen RECEIVES isDoctor PARAMETER:
//    BEFORE: const ScheduleScreen() — screen fetched role from Firestore on every mount.
//    NOW: const ScheduleScreen(isDoctor: false) — zero network call for role.
//
// 4. kPrimaryBlue AND kSpecialties FROM CONSTANTS:
//    BEFORE: primaryBlue was a local Color variable in this file.
//    NOW: kPrimaryBlue imported from utils/constants.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../services/database_service.dart'; // replaces all direct Firestore calls
import '../../models/user.dart';
import '../../utils/constants.dart'; // kPrimaryBlue — was a local variable before
import '../../utils/date_utils.dart'; // parseDate shared helper
import '../../widgets/action_button.dart'; // replaces private _buildActionBtn method
import 'doctor_search_screen.dart';
import 'ai_chat_screen.dart';
import '../common/schedule_screen.dart';
import '../common/profile_screen.dart';
import '../common/chats_list_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const PatientHomeContent(),
    const ScheduleScreen(isDoctor: false),
    const ChatsListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: kPrimaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'My Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home content tab ──────────────────────────────────────────────────────────

class PatientHomeContent extends StatefulWidget {
  const PatientHomeContent({super.key});

  @override
  State<PatientHomeContent> createState() => _PatientHomeContentState();
}

class _PatientHomeContentState extends State<PatientHomeContent> {
  final _db = DatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh the countdown banner every minute.
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) { if (mounted) setState(() {}); },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                stops: const [0.0, 0.4],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello,',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            StreamBuilder<UserModel?>(
                              stream:
                                  user?.uid != null
                                      ? _db.streamUser(user!.uid)
                                      : null,
                              builder: (context, snapshot) {
                                String fullName =
                                    snapshot.data?.name ?? 'Patient';
                                List<String> parts = fullName.trim().split(' ');
                                String display =
                                    parts.length > 2
                                        ? '${parts[0]} ${parts[1]}'
                                        : fullName;
                                return Text(
                                  display,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kPrimaryBlue.withOpacity(0.5),
                            width: 2,
                          ),
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE0E7FF),
                          child: Icon(
                            Icons.person,
                            color: kPrimaryBlue,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Upcoming appointment banner
                  StreamBuilder<dynamic>(
                    stream:
                        user?.uid != null
                            ? _db.streamAcceptedAppointmentsForPatient(
                              user!.uid,
                            )
                            : null,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return _buildEmptyBanner();

                      var docs = snapshot.data!.docs;
                      var futureAppointments =
                          docs
                              .map((doc) {
                                final data = doc.data() as Map;
                                return {
                                  'data': data,
                                  'date': parseDate(data['date']),
                                };
                              })
                              .where(
                                (item) =>
                                    (item['date'] as DateTime).isAfter(
                                      DateTime.now(),
                                    ),
                              )
                              .toList();

                      if (futureAppointments.isEmpty) return _buildEmptyBanner();

                      futureAppointments.sort(
                        (a, b) => (a['date'] as DateTime).compareTo(
                          b['date'] as DateTime,
                        ),
                      );
                      final next = futureAppointments.first;

                      return _buildTimerBanner(
                        next['date'] as DateTime,
                        (next['data'] as Map)['doctor_name'] ?? 'Doctor',
                      );
                    },
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 15),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.1,
                      children: [
                        ActionButton(
                          icon: Icons.person_search_rounded,
                          title: 'Find Doctor',
                          color: Colors.blue,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => const DoctorSearchScreen(),
                                ),
                              ),
                        ),
                        ActionButton(
                          icon: Icons.smart_toy_rounded,
                          title: 'AI Assistant',
                          color: Colors.purple,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => const AiChatScreen(),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBanner(DateTime apptDate, String doctorName) {
    Duration diff = apptDate.difference(DateTime.now());
    String timeText =
        diff.inDays > 0
            ? '${diff.inDays} Days, ${diff.inHours % 24} Hours'
            : '${diff.inHours} Hours, ${diff.inMinutes % 60} Minutes';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBlue, kPrimaryBlue.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Appointment',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            timeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'with Dr. $doctorName',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No upcoming appointments yet.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Book Now?',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
