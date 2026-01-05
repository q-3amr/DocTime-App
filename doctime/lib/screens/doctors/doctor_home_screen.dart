import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Required for Blur

// Ensure these imports are correct for your project structure
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
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

  // Your primary blue color
  final Color primaryBlue = const Color(0xFF407CE2);

  final List<Widget> _pages = [
    const DoctorDashboard(),        
    const ScheduleScreen(),         
    const DoctorRequestsScreen(),   
    const ProfileScreen(),          
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false, // Set to false for standard bottom bar behavior
      body: IndexedStack(index: _selectedIndex, children: _pages),
      
      // --- Standard Default Bottom Bar ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), 
              blurRadius: 10, 
              offset: const Offset(0, -5)
            )
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          
          // Using standard labels or hidden based on your preference. 
          // Kept hidden here for cleaner look, change to true if you want text.
          showSelectedLabels: false, 
          showUnselectedLabels: false, 
          
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded, size: 28), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded, size: 28), label: "Schedule"),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active_rounded, size: 28), label: "Requests"),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: "Profile"),
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
          // 1. Rich Background (Gradient + Blobs)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF2F6FF), // Light Blue
                  Color(0xFFE8F1FF), // Bluish White
                  Color(0xFFF5F3FF), // Faint Purple
                ],
              ),
            ),
          ),
          
          // Decorative Blob 1
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryBlue.withOpacity(0.15),
              ),
            ),
          ),
          // Decorative Blob 2
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.1),
              ),
            ),
          ),
          // Blur Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.transparent),
          ),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- Header: Text Left, Picture Right ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Welcome Text & Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back,",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('doctors').doc(user?.uid).get(),
                              builder: (context, snapshot) {
                                // Loading State
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    width: 100, height: 24, 
                                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))
                                  );
                                }
                                String name = "Doctor";
                                if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                                  name = snapshot.data!.get('name') ?? "Doctor";
                                }
                                return Text(
                                  "Dr. $name",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // User Picture (Replaces Logo)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFE0E7FF),
                          child: Icon(Icons.person, color: primaryBlue, size: 30),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- Notification Banner (Glassmorphism) ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('doctor_id', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Loading State for Banner
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      int pendingCount = 0;
                      if (snapshot.hasData) {
                        var docs = snapshot.data!.docs;
                        pendingCount = docs.where((d) => d['status'] == 'pending').length;
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryBlue, const Color(0xFF2E5BFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text("Pending Requests", style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                                const SizedBox(height: 10),
                                Text("$pendingCount", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
                                const SizedBox(height: 4),
                                const Text("Waiting for approval", style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 30),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- Quick Actions Grid ---
                  Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                  ),
                  const SizedBox(height: 15),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('appointments').where('doctor_id', isEqualTo: user?.uid).snapshots(),
                    builder: (context, snapshot) {
                       // Loading check to prevent white screen/crash
                       if (!snapshot.hasData) {
                         return const Center(child: CircularProgressIndicator());
                       }

                       var docs = snapshot.data!.docs;
                       int upcomingCount = docs.where((d) => d['status'] == 'accepted').length;
                       int completedCount = docs.where((d) => d['status'] == 'completed').length;
                      
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildGlassCard(
                            context,
                            Icons.chat_bubble_rounded,
                            "My Chats",
                            "Messages",
                            const Color(0xFF6C63FF),
                            () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ChatsListScreen())),
                          ),
                          _buildGlassCard(
                            context,
                            Icons.calendar_month_rounded,
                            "$upcomingCount Upcoming",
                            "Schedule",
                            const Color(0xFFFFA726),
                            () {},
                          ),
                          _buildGlassCard(
                            context,
                            Icons.tune_rounded,
                            "Availability",
                            "Manage Slots",
                            const Color(0xFF26A69A),
                            () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ManageSlotsScreen())),
                          ),
                          _buildGlassCard(
                            context,
                            Icons.history_rounded,
                            "$completedCount Done",
                            "History",
                            const Color(0xFFEC407A),
                            () {},
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Glass Card Widget
  Widget _buildGlassCard(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6), // Glass effect
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey.shade800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}