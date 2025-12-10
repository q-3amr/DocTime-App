import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart'; // 👈 تأكد إنك عامل هاد الملف

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الألوان
    final Color primaryBlue = const Color(0xFF407CE2);
    final Color textGrey = const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 1), // فراغ مرن من فوق

              // 🛑 1. مكان اللوجو (مع إطار وتدوير حواف زي الأيقونة)
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30), // حواف ناعمة
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.15), // ظل أزرق خفيف
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(15), // حشوة داخلية
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/doctime_logo1.png', // 👈 تأكد من اسم اللوجو
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 2. النصوص (زي الصورة اللي بعثتها)
              Text(
                "Welcome to",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textGrey,
                ),
              ),
              
              Text(
                "DocTime",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900, // خط عريض جداً
                  color: primaryBlue,
                  letterSpacing: 1.0,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                "Your Medical Appointment\n& AI Assistant",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(flex: 2), // فراغ بيفصل المحتوى عن الأزرار

              // 3. الأزرار (واحد معبى وواحد مفرغ)
              
              // زر LOGIN
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // 👇 أنيميشن الانزلاق من الأسفل
                    Navigator.of(context).push(
                      _createSlideRoute(const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 5,
                    shadowColor: primaryBlue.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // تدوير كامل (Pill shape)
                    ),
                  ),
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // زر REGISTER (مفرغ - Outlined)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: () {
                    // 👇 نفس الأنيميشن لصفحة التسجيل
                    Navigator.of(context).push(
                      _createSlideRoute(const SignupScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryBlue, width: 2), // حدود زرقاء
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "REGISTER",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: primaryBlue, // النص أزرق
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 🪄 دالة الأنيميشن الجديد (Slide Transition)
  // بتخلي الشاشة الجديدة تطلع "زحلقة" من تحت لفوق
  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // نقطة البداية: (0.0, 1.0) يعني من تحت الشاشة
        const begin = Offset(0.0, 1.0);
        // نقطة النهاية: (0.0, 0.0) يعني مكانها الطبيعي
        const end = Offset.zero;
        // نوع الحركة: easeOutQuart (سريعة بالبداية وبتخف بالآخر - ناعمة جداً)
        const curve = Curves.easeOutQuart;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600), // سرعة الحركة
    );
  }
}