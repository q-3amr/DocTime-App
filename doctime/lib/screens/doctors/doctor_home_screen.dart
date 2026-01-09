  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import '../common/schedule_screen.dart'; 
  import '../common/profile_screen.dart'; 
  import 'doctor_requests_screen.dart';
  import 'manage_slots_screen.dart';
  import '../common/chats_list_screen.dart'; 

  class DoctorHomeScreen extends StatefulWidget {
    const DoctorHomeScreen({super.key});

    @override
    State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
  }

  class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
    int _selectedIndex = 0; 
    final User? user = FirebaseAuth.instance.currentUser;

    final List<Widget> _pages = [
      const DoctorDashboard(),        
      const ScheduleScreen(),         
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
            selectedItemColor: const Color(0xFF407CE2),
            unselectedItemColor: Colors.grey.shade400,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: "Schedule"),
              BottomNavigationBarItem(icon: Icon(Icons.notifications_active_rounded), label: "Requests"),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Profile"),
            ],
          ),
        ),
      );
    }
  }

  class DoctorDashboard extends StatelessWidget {
    const DoctorDashboard({super.key});

    @override
    Widget build(BuildContext context) {
      final User? user = FirebaseAuth.instance.currentUser;
      final Color primaryBlue = const Color(0xFF407CE2);

      return Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, 
                  end: Alignment.bottomCenter, 
                  colors: [primaryBlue.withOpacity(0.15), Colors.white],
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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welcome back,", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                              builder: (context, snapshot) {
                                String name = snapshot.data?['name'] ?? "Doctor";
                                return Text("Dr. $name", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900));
                              },
                            ),
                          ],
                        ),
                        // 👇 User Photo Replaced Here
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryBlue.withOpacity(0.5), width: 2),
                            color: Colors.white,
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFE0E7FF),
                            child: Icon(Icons.person, color: primaryBlue, size: 28),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Stats & Data
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('doctor_id', isEqualTo: user?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        var docs = snapshot.data!.docs;
                        int pendingCount = docs.where((d) => d['status'] == 'pending').length;
                        int completedCount = docs.where((d) => d['status'] == 'completed').length;
                        int upcomingCount = docs.where((d) => d['status'] == 'accepted').length;

                        return Column(
                          children: [
                            // Banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Pending Requests", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        Text("$pendingCount Pending", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 10),
                                        const Text("Tap 'Requests' below to approve.", style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.notifications_active, color: Colors.white, size: 30),
                                  )
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),
                            const Align(alignment: Alignment.centerLeft, child: Text("Quick Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            const SizedBox(height: 15),

                            // Grid Cards (Unified Design)
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 20, 
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.1,
                              children: [
                                _buildActionBtn(context, Icons.chat_bubble_rounded, "My Chats", Colors.indigo, () {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => const ChatsListScreen()));
                                }),

                                _buildActionBtn(context, Icons.calendar_today_rounded, "$upcomingCount Upcoming", Colors.orange, () {
                                }),
                                
                                _buildActionBtn(context, Icons.access_time_filled_rounded, "Manage Slots", Colors.teal, () {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => const ManageSlotsScreen()));
                                }),

                                _buildActionBtn(context, Icons.check_circle_rounded, "$completedCount Done", Colors.green, () {}),
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

    Widget _buildActionBtn(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: Colors.grey.shade200), 
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))], 
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 34),
              ),
              const SizedBox(height: 15),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      );  
    }
  }