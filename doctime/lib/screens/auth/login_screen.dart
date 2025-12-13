import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../patient/patient_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isObscure = true;

  void handleLogin() async {
    setState(() => isLoading = true);
    try {
      // 1. تسجيل الدخول (فايربيس بتأكد من الإيميل والباسورد)
      await AuthService().signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && mounted) {
        // 2. فحص هل هو دكتور؟
        DocumentSnapshot docSnap = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(user.uid)
            .get();

        if (docSnap.exists) {
          // 👨‍⚕️ طلع دكتور - هسا بنفحص التوثيق
          Map<String, dynamic> data = docSnap.data() as Map<String, dynamic>;
          bool isVerified = data['isVerified'] ?? false; // القيمة الافتراضية false

          if (isVerified) {
             // ✅ موثق: وديه على شاشة الدكتور
             // Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DoctorHomeScreen()));
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Welcome Doctor!")));
          } else {
             // ❌ مش موثق: اطرده
             await AuthService().signOut(); // 👈 بنسجل خروجه فوراً
             if (mounted) {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   title: const Text("Pending Approval"),
                   content: const Text("Your account is currently under review by the admin. Please wait for approval."),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                   ],
                 ),
               );
             }
          }
        } else {
          // 👤 طلع مريض -> وديه على شاشة المريض (المريض ما بده توثيق)
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (c) => const PatientHomeScreen())
          );
        }
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF407CE2);
    final Color labelColor = const Color(0xFF374151);
    final Color borderColor = const Color(0xFFD1D5DB);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // 🛠️ الحل السحري لتثبيت الفوتر وإلغاء السكرول الزايد
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // بجبره يوخذ طول الشاشة كاملة
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),

                        // 1. الصورة
                        Container(
                          height: 250, 
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/doctor_login.png', 
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Icon(Icons.image_not_supported, size: 80, color: Colors.grey.shade300),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. العنوان
                        Text(
                          "Log in",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: primaryBlue,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 3. الحقول
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email Address", style: TextStyle(color: labelColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: emailController,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: "Enter your Email Address",
                                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: borderColor, width: 2.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: primaryBlue, width: 2.5),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Password", style: TextStyle(color: labelColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: passwordController,
                              obscureText: isObscure,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: "Enter your Password",
                                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: borderColor, width: 2.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: primaryBlue, width: 2.5),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.grey.shade600,
                                    size: 26,
                                  ),
                                  onPressed: () => setState(() => isObscure = !isObscure),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(color: labelColor, fontSize: 14, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // زر الدخول
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                          ),
                        ),

                        // 🛑 هذا السطر هو السر: بيوخذ كل المساحة الفاضية وبدفش الفوتر لتحت
                        const Spacer(),

                        // الفوتر (ثابت بأسفل الشاشة)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: TextStyle(color: labelColor, fontSize: 15, fontWeight: FontWeight.w600)),
                              GestureDetector(
                                onTap: () {
                                  // 👇 هون استخدمنا pushReplacement عشان نبدل الصفحة
                                  Navigator.pushReplacement(
                                    context, 
                                    MaterialPageRoute(builder: (context) => const SignupScreen())
                                  );
                                },
                                child: Text(
                                  "Sign up",
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    decoration: TextDecoration.underline,
                                    decorationColor: primaryBlue,
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
              ),
            );
          },
        ),
      ),
    );
  }
}