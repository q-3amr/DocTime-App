import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'doctor_search_screen.dart';
import 'doctor_details_screen.dart'; 
import 'ai_chat_screen.dart';        
import '../common/schedule_screen.dart'; 
import '../common/profile_screen.dart';  
import '../common/chats_list_screen.dart'; 

// 1️⃣ الإطار الرئيسي (Shell)
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0; 

  // 📺 قائمة الصفحات للمريض
  final List<Widget> _pages = [
    const PatientHomeContent(),     // 0: الرئيسية
    const ScheduleScreen(),         // 1: المواعيد
    const ChatsListScreen(),        // 2: الشات
    const ProfileScreen(),          // 3: البروفايل
  ];

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 👇 الرسيفر
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      // الريموت (البار السفلي)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 14,
          unselectedFontSize: 14,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded, size: 26), label: "Schedule"),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded, size: 26), label: "Chat"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 28), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

// 2️⃣ محتوى الرئيسية للمريض (الداشبورد)
// 2️⃣ محتوى الرئيسية للمريض (الداشبورد) مع خلفية تدرج لوني فخمة
class PatientHomeContent extends StatefulWidget {
  const PatientHomeContent({super.key});

  @override
  State<PatientHomeContent> createState() => _PatientHomeContentState();
}

class _PatientHomeContentState extends State<PatientHomeContent> {
  final User? user = AuthService().currentUser;
  String userName = "Patient";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  void _fetchUserName() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists && mounted) {
        setState(() { userName = userDoc['name'] ?? "Patient"; });
      }
    }
  }

  void _handleLogout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);
    final Color lightBg = const Color(0xFFF5F7FA);
    const double defaultPadding = 24.0; 

    return Scaffold(
      // backgroundColor: Colors.white, // شلناها عشان التدرج يبين
      body: Stack(
        children: [
          
          // 🎨 الحركة الجديدة: تدرج لوني ناعم في الخلفية
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, // يبدأ من فوق
                end: Alignment.bottomCenter, // ينتهي تحت
                colors: [
                  primaryBlue.withOpacity(0.15), // أزرق فاتح جداً من فوق
                  Colors.white, // بصير أبيض بالنص
                  Colors.white, // وبضل أبيض تحت
                ],
                stops: const [0.0, 0.5, 1.0], // توزيع الألوان: الأزرق بوخذ بس النص الفوقاني
              ),
            ),
          ),

          // 📦 المحتوى الأصلي (فوق الخلفية)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryBlue, width: 2.5)),
                            child: const CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Hello,", style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.grey, size: 28),
                        onPressed: _handleLogout,
                      )
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Search Bar
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18), 
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                    ),
                    child: TextField(
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 30),
                        hintText: "Search doctor...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Early protection", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text("Check your health", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: () {
                                   Navigator.push(context, MaterialPageRoute(builder: (c) => const DoctorDetailsScreen(doctorName: "Qusai", specialty: "SE")));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Book Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.medical_services_rounded, color: Colors.white, size: 40),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  const Text("Services", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),

                  // Grid Buttons
                  Expanded(
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.2, 
                      children: [
                        _buildSquareBtn(Icons.person_search_rounded, "Find Doctor", Colors.blue, () {
                            Navigator.push(context, MaterialPageRoute(builder: (c) => const DoctorSearchScreen()));
                        }),
                        _buildSquareBtn(Icons.smart_toy_rounded, "AI Assistant", Colors.purple, () {
                            Navigator.push(context, MaterialPageRoute(builder: (c) => const AiChatScreen()));
                        }),
                        _buildSquareBtn(Icons.calendar_month_rounded, "Appointments", Colors.orange, () {
                            Navigator.push(context, MaterialPageRoute(builder: (c) => const ScheduleScreen()));
                        }),
                        _buildSquareBtn(Icons.assignment_rounded, "Records", Colors.teal, () {}),
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

  Widget _buildSquareBtn(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: Colors.grey.shade200, width: 1.5), 
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15), 
              blurRadius: 12, 
              offset: const Offset(0, 6), 
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              title, 
              style: const TextStyle(
                fontWeight: FontWeight.w700, 
                fontSize: 15, 
                color: Colors.black87
              )
            ),
          ],
        ),
      ),
    );
  }
}