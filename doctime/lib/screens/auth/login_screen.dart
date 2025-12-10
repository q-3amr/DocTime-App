import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';

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
      await AuthService().signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // الألوان مع تعديل درجة الوضوح
    final Color primaryBlue = const Color(0xFF407CE2);
    final Color labelColor = const Color(0xFF374151); // غمقت اللون صار أقرب للأسود
    final Color borderColor = const Color(0xFFD1D5DB); // غمقت حدود البوكس

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // 1. الصورة
              Container(
                height: 280, 
                width: double.infinity,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/doctor_login.png', 
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Icon(Icons.image_not_supported, size: 100, color: Colors.grey.shade300),
                ),
              ),

              const SizedBox(height: 20),

              // 2. العنوان (Log in) - صار أضخم وأوضح
              Text(
                "Log in",
                style: TextStyle(
                  fontSize: 36, // كبرته لـ 36
                  fontWeight: FontWeight.w900, // أقصى درجات العرض (Extra Bold)
                  color: primaryBlue,
                  letterSpacing: 1.2, // تباعد عشان الفخامة
                ),
              ),

              const SizedBox(height: 40),

              // 3. حقل الإيميل
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Email Address",
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 16, // كبرت الخط
                      fontWeight: FontWeight.bold, // صار عريض
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16), // خط الكتابة نفسه عريض
                    decoration: InputDecoration(
                      hintText: "Enter your Email Address",
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.normal),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18), // كبرت الحشوة
                      filled: true,
                      fillColor: Colors.grey.shade50, // خلفية سكني خفيفة جداً للتمييز
                      
                      // الحدود وهي مرتاحة (سميكة وواضحة)
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16), // زوايا دائرية أكثر
                        borderSide: BorderSide(color: borderColor, width: 2.0), // 👈 سماكة 2 بدل 1
                      ),
                      
                      // الحدود لما تكبس (زرقاء وسميكة)
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primaryBlue, width: 2.5), // 👈 سماكة 2.5
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 4. حقل الباسوورد
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Password",
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: isObscure,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Enter your Password",
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.normal),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor, width: 2.0), // سماكة 2
                      ),
                      
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primaryBlue, width: 2.5), // سماكة 2.5
                      ),
                      
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey.shade600,
                          size: 26, // كبرت الأيقونة
                        ),
                        onPressed: () => setState(() => isObscure = !isObscure),
                      ),
                    ),
                  ),
                ],
              ),

              // رابط نسيان كلمة السر
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: labelColor, 
                      fontSize: 14, 
                      fontWeight: FontWeight.w700, // عريض
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 5. زر الدخول (Login)
              SizedBox(
                width: double.infinity,
                height: 60, // زر ضخم
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 2, // ضفت ظل خفيف
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Login",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                      ),
                ),
              ),

              const SizedBox(height: 30),

              // الفوتر
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: labelColor, fontSize: 15, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}