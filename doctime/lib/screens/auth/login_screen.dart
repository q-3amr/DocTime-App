import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // هون بنخزن النص اللي بيكتبه المستخدم
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 1. لون خلفية الشاشة
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // 2. هوامش من الجوانب
          child: SingleChildScrollView( // عشان اذا الكيبورد طلع ما يغطي الشاشة
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 3. توسيط العناصر
              crossAxisAlignment: CrossAxisAlignment.stretch, // تعبئة العرض
              children: [
                const SizedBox(height: 50),
                
                // --- الشعار أو الصورة ---
                const Icon(
                  Icons.local_hospital, // ممكن تستبدلها بـ Image.asset
                  size: 100,
                  color: Colors.blue, // لون الشعار
                ),
                
                const SizedBox(height: 30),

                // --- عنوان الصفحة ---
                const Text(
                  "Welcome Back!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 40),

                // --- حقل الإيميل ---
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // تدوير الحواف
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --- حقل الباسوورد ---
                TextField(
                  controller: passwordController,
                  obscureText: true, // عشان يخفي النص
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // --- نسيان كلمة السر ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("Forgot Password?"),
                  ),
                ),

                const SizedBox(height: 20),

                // --- زر الدخول ---
                ElevatedButton(
                  onPressed: () {
                    // هون رح نحط كود الربط مع الفايربيس بعدين
                    print("Email: ${emailController.text}");
                    print("Password: ${passwordController.text}");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // لون الزر
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // تدوير حواف الزر
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}