import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../services/database_service.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/action_button.dart';
import '../../widgets/star_rating_widget.dart';
import 'doctor_search_screen.dart';
import 'ai_chat_screen.dart';
import 'patient_map_screen.dart'; 
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
    final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
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
                icon: Icon(Icons.home_rounded), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_rounded), label: 'My Bookings'),
            BottomNavigationBarItem(
              icon: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: _uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data.containsKey('isRead') &&
                          data.containsKey('lastMessageSenderId')) {
                        return data['isRead'] == false &&
                            data['lastMessageSenderId'] != _uid;
                      }
                      return false;
                    }).length;
                  }
                  return _buildBadgeIcon(
                      Icons.chat_bubble_outline_rounded, unreadCount);
                },
              ),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
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
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}

class PatientHomeContent extends StatefulWidget {
  const PatientHomeContent({super.key});
  @override
  State<PatientHomeContent> createState() => _PatientHomeContentState();
}

class _PatientHomeContentState extends State<PatientHomeContent> {
  final _db = DatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;
  StreamSubscription? _feedbackListener;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startFeedbackListener();
  }

  @override
  void dispose() {
    _feedbackListener?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  
  void _startFeedbackListener() {
    if (user?.uid == null) return;
    _feedbackListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('patient_id', isEqualTo: user!.uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        if (data['hasFeedback'] != true && data['isDismissed'] != true) {
          _showFeedbackPopup(context, doc.id);
          break;
        }
      }
    });
  }

  void _showFeedbackPopup(BuildContext context, String appointmentId) {
    double dialogRating = 5.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    
                    
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          const Icon(Icons.stars_rounded,
                              color: Colors.amber, size: 50),
                          const SizedBox(height: 10),
                          const Text('Feedback',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 22)),
                          const SizedBox(height: 15),
                          const Text(
                            'Your appointment has finished!\nPlease share your experience with us.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                StarRatingWidget(
                                  initialRating: dialogRating,
                                  starSize: 36,
                                  onRatingChanged: (val) =>
                                      setDialogState(() => dialogRating = val),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dialogRating == 1
                                      ? 'Poor'
                                      : dialogRating == 2
                                          ? 'Fair'
                                          : dialogRating == 3
                                              ? 'Good'
                                              : dialogRating == 4
                                                  ? 'Very Good'
                                                  : 'Excellent',
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _feedbackController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Write your feedback here...',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200)),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: () async {
                                final apptDoc = await FirebaseFirestore.instance
                                    .collection('appointments')
                                    .doc(appointmentId)
                                    .get();
                                final doctorId =
                                    apptDoc.data()?['doctor_id'] as String?;

                                await FirebaseFirestore.instance
                                    .collection('appointments')
                                    .doc(appointmentId)
                                    .update({
                                  'hasFeedback': true,
                                  'feedback_text': _feedbackController.text,
                                  'isReviewSeen': false,
                                  'rating': dialogRating,
                                });

                                if (doctorId != null && doctorId.isNotEmpty) {
                                  await _db
                                      .updateDoctorAggregateRating(doctorId);
                                }

                                _feedbackController.clear();
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Confirm',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () async {
                        
                        await FirebaseFirestore.instance
                            .collection('appointments')
                            .doc(appointmentId)
                            .update({
                          'isDismissed': true, 
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
            child: Padding(
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
                              Text('Hello,',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16)),
                              StreamBuilder<UserModel?>(
                                stream: user?.uid != null
                                    ? _db.streamUser(user!.uid)
                                    : null,
                                builder: (context, snapshot) {
                                  String name =
                                      snapshot.data?.name ?? 'Patient';
                                  return Text(name.split(' ')[0],
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900));
                                },
                              ),
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
                        ? _db.streamAcceptedAppointmentsForPatient(user!.uid)
                        : null,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return _buildEmptyBanner();
                      var docs = snapshot.data!.docs;
                      var future = docs
                          .map((doc) => {
                                'data': doc.data() as Map,
                                'date': parseDate((doc.data() as Map)['date'])
                              })
                          .where((item) => (item['date'] as DateTime)
                              .isAfter(DateTime.now()))
                          .toList();
                      if (future.isEmpty) return _buildEmptyBanner();
                      future.sort((a, b) => (a['date'] as DateTime)
                          .compareTo(b['date'] as DateTime));
                      final next = future.first;
                      return LiveTimerBanner(
                          date: next['date'] as DateTime,
                          doctorName:
                              (next['data'] as Map)['doctor_name'] ?? 'Doctor');
                    },
                  ),
                  const SizedBox(height: 25),
                  const Text('Quick Actions',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 15),

                  Expanded(
                    child: ListView(
                      children: [
                        ActionButton(
                            icon: Icons.person_search_rounded,
                            title: 'Find Doctor',
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) =>
                                        const DoctorSearchScreen()))),
                        const SizedBox(height: 15),
                        ActionButton(
                            icon: Icons.smart_toy_rounded,
                            title: 'AI Assistant',
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => const AiChatScreen()))),
                        const SizedBox(height: 15),
                        
                        ActionButton(
                            icon: Icons.map_outlined,
                            title: 'Clinic Map',
                            color: Colors.green.shade600,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => const PatientMapScreen()))),
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
                  offset: const Offset(0, 10))
            ]),
        child: Row(children: [
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('No upcoming appointments yet.',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 5),
                Text('Book Now?',
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w900))
              ])),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.calendar_month_rounded,
                  color: Colors.grey, size: 30))
        ]));
  }
}

class LiveTimerBanner extends StatefulWidget {
  final DateTime date;
  final String doctorName;

  const LiveTimerBanner(
      {super.key, required this.date, required this.doctorName});

  @override
  State<LiveTimerBanner> createState() => _LiveTimerBannerState();
}

class _LiveTimerBannerState extends State<LiveTimerBanner> {
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    
    _bannerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Duration diff = widget.date.difference(DateTime.now());

    
    if (diff.isNegative) return const SizedBox.shrink();

    String timeText = diff.inDays > 0
        ? '${diff.inDays} Days, ${diff.inHours % 24} Hours'
        : '${diff.inHours} Hours, ${diff.inMinutes % 60} Minutes';

    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryBlue.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Upcoming Appointment',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(timeText,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('with Dr. ${widget.doctorName}',
              style: const TextStyle(color: Colors.white, fontSize: 16))
        ]));
  }
}
