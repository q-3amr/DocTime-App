// ─────────────────────────────────────────────────────────────────────────────
// WHAT WAS CHANGED IN THIS FILE:
//
// 1. DIRECT FIRESTORE CALLS REPLACED:
//    BEFORE: FutureBuilder<DocumentSnapshot> from Firestore to get the doctor's name.
//         + StreamBuilder<QuerySnapshot> from Firestore to count appointments.
//    NOW: DatabaseService().getUserById(uid) — typed UserModel?
//         DatabaseService().streamAppointmentsForDoctor(uid)
//
// 2. DATE HELPERS FROM SHARED UTILS:
//    BEFORE: had private _parseDate() and _isExpired() methods.
//    NOW: uses parseDate() and isExpiredAppointment() from date_utils.dart.
//    (same helpers were duplicated in 4 other screens).
//
// 3. ActionButton WIDGET USED:
//    BEFORE: had a private _buildActionBtn(icon, title, color, onTap) method.
//    NOW: uses shared ActionButton from widgets/action_button.dart.
//
// 4. ScheduleScreen RECEIVES isDoctor PARAMETER:
//    BEFORE: const ScheduleScreen() — screen fetched role from Firestore on every mount.
//    NOW: const ScheduleScreen(isDoctor: true) — zero network call for role.
//
// 5. kPrimaryBlue FROM CONSTANTS:
//    BEFORE: primaryBlue was a local Color variable.
//    NOW: kPrimaryBlue imported from utils/constants.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart'; // replaces all direct Firestore calls
import '../../utils/constants.dart'; // kPrimaryBlue — was a local variable before
import '../../utils/date_utils.dart'; // parseDate, isExpiredAppointment — were private methods
import '../../widgets/action_button.dart'; // replaces private _buildActionBtn method
import '../common/schedule_screen.dart';
import '../common/profile_screen.dart';
import '../common/chats_list_screen.dart';
import '../patient/doctor_search_screen.dart';
import 'doctor_requests_screen.dart';
import 'manage_slots_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DoctorDashboard(),
    const ScheduleScreen(isDoctor: true),
    const DoctorRequestsScreen(),
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
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active_rounded),
              label: 'Requests',
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

// ── Dashboard tab ─────────────────────────────────────────────────────────────

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final User? user = FirebaseAuth.instance.currentUser;

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
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            FutureBuilder(
                              future: db.getUserById(user?.uid ?? ''),
                              builder: (context, snapshot) {
                                String fullName =
                                    snapshot.data?.name ?? 'Doctor';
                                List<String> parts =
                                    fullName.trim().split(' ');
                                String display =
                                    parts.length > 2
                                        ? '${parts[0]} ${parts[1]}'
                                        : fullName;
                                return Text(
                                  'Dr. $display',
                                  style: const TextStyle(
                                    fontSize: 22,
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

                  // Stats cards from appointments stream
                  StreamBuilder<dynamic>(
                    stream:
                        user?.uid != null
                            ? db.streamAppointmentsForDoctor(user!.uid)
                            : null,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      final pending =
                          docs.where((d) => d['status'] == 'pending').length;
                      final upcoming =
                          docs
                              .where((d) {
                                if (d['status'] != 'accepted') return false;
                                return !isExpiredAppointment(
                                  parseDate(d['date']),
                                );
                              })
                              .length;
                      final completed =
                          docs
                              .where((d) => d['status'] == 'completed')
                              .length;

                      return Column(
                        children: [
                          // Pending banner
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
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pending Requests',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '$pending Pending',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Tap 'Requests' below to approve.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Quick Dashboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Completed row
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green.shade700,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$completed',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      Text(
                                        'Completed Appointments',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Action buttons grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.1,
                            children: [
                              ActionButton(
                                icon: Icons.chat_bubble_rounded,
                                title: 'My Chats',
                                color: Colors.indigo,
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (c) => const ChatsListScreen(),
                                      ),
                                    ),
                              ),
                              ActionButton(
                                icon: Icons.calendar_today_rounded,
                                title: '$upcoming Upcoming',
                                color: Colors.orange,
                                onTap: () {},
                              ),
                              ActionButton(
                                icon: Icons.access_time_filled_rounded,
                                title: 'Manage Slots',
                                color: Colors.teal,
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (c) => const ManageSlotsScreen(),
                                      ),
                                    ),
                              ),
                              ActionButton(
                                icon: Icons.person_search_rounded,
                                title: 'Find Doctor',
                                color: Colors.blue,
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (c) => const DoctorSearchScreen(),
                                      ),
                                    ),
                              ),
                            ],
                          ),
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
