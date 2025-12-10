import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 1. المفاتيح والتحكم
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  
  // حقول الدكتور الإضافية
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  bool isLoading = false;
  bool isObscurePass = true;
  bool isObscureConfirm = true;
  bool isDoctor = false; // 👈 هاد اللي بغير شكل الشاشة

  // 2. دالة التسجيل
  void handleSignup() async {
    // فحص تطابق الباسوورد
    if (passwordController.text != confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await AuthService().signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        role: isDoctor ? 'doctor' : 'patient', // تحديد الدور
        specialty: isDoctor ? specialtyController.text.trim() : null,
        location: isDoctor ? locationController.text.trim() : null,
      );
      
      // إذا نجح، بنرجع لصفحة اللوجين عشان يدخل
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please login.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // نفس ألوان اللوجين بالملي
    final Color primaryBlue = const Color(0xFF407CE2);
    final Color labelColor = const Color(0xFF374151);
    final Color borderColor = const Color(0xFFD1D5DB);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // العنوان الكبير (بدون صورة عشان نوفر مساحة)
                Text(
                  "Sign up",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900, // Extra Bold
                    color: primaryBlue,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Text(
                  "Create your new account",
                  style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 30),

                // 1. الاسم الكامل
                _buildField(
                  label: "Full Name",
                  controller: nameController,
                  hint: "Enter your full name",
                  icon: Icons.person_outline,
                  borderColor: borderColor,
                  primaryBlue: primaryBlue,
                  labelColor: labelColor,
                ),

                const SizedBox(height: 20),

                // 2. الإيميل
                _buildField(
                  label: "Email Address",
                  controller: emailController,
                  hint: "Enter your email",
                  icon: Icons.email_outlined,
                  borderColor: borderColor,
                  primaryBlue: primaryBlue,
                  labelColor: labelColor,
                ),

                const SizedBox(height: 20),

                // 3. الباسوورد
                _buildField(
                  label: "Password",
                  controller: passwordController,
                  hint: "Create password",
                  icon: Icons.lock_outline,
                  borderColor: borderColor,
                  primaryBlue: primaryBlue,
                  labelColor: labelColor,
                  isPass: true,
                  isObscure: isObscurePass,
                  onEyeTap: () => setState(() => isObscurePass = !isObscurePass),
                ),

                const SizedBox(height: 20),

                // 4. تأكيد الباسوورد
                _buildField(
                  label: "Confirm Password",
                  controller: confirmPassController,
                  hint: "Re-enter password",
                  icon: Icons.lock_outline,
                  borderColor: borderColor,
                  primaryBlue: primaryBlue,
                  labelColor: labelColor,
                  isPass: true,
                  isObscure: isObscureConfirm,
                  onEyeTap: () => setState(() => isObscureConfirm = !isObscureConfirm),
                ),

                const SizedBox(height: 25),

                // 🛑 سويتش: التسجيل كطبيب
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDoctor ? primaryBlue.withOpacity(0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDoctor ? primaryBlue : borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.medical_services, color: isDoctor ? primaryBlue : Colors.grey),
                      const SizedBox(width: 10),
                      Text(
                        "Register as a Doctor",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDoctor ? primaryBlue : labelColor,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isDoctor,
                        activeColor: primaryBlue,
                        onChanged: (val) => setState(() => isDoctor = val),
                      ),
                    ],
                  ),
                ),

                // 👇 هاي الحقول بتطلع بس لما يكبس السويتش
                if (isDoctor) ...[
                  const SizedBox(height: 20),
                  _buildField(
                    label: "Specialty",
                    controller: specialtyController,
                    hint: "e.g. Cardiologist",
                    icon: Icons.work_outline,
                    borderColor: borderColor,
                    primaryBlue: primaryBlue,
                    labelColor: labelColor,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    label: "Location",
                    controller: locationController,
                    hint: "e.g. Amman, Jordan",
                    icon: Icons.location_on_outlined,
                    borderColor: borderColor,
                    primaryBlue: primaryBlue,
                    labelColor: labelColor,
                  ),
                ],

                const SizedBox(height: 30),

                // زر التسجيل
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                        ),
                  ),
                ),

                const SizedBox(height: 20),

                // الفوتر
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: labelColor, fontSize: 15, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context), // رجوع للوجين
                      child: Text(
                        "Login",
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget مساعد عشان نختصر الكود وما نكرره
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color borderColor,
    required Color primaryBlue,
    required Color labelColor,
    bool isPass = false,
    bool isObscure = false,
    VoidCallback? onEyeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 16,
            fontWeight: FontWeight.bold, // نفس سماكة اللوجين
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPass ? isObscure : false,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.normal),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            filled: true,
            fillColor: Colors.grey.shade50,
            
            // الحدود السميكة (2.0)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            
            // الحدود النشطة (2.5)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryBlue, width: 2.5),
            ),

            suffixIcon: isPass 
              ? IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.grey.shade600,
                    size: 26,
                  ),
                  onPressed: onEyeTap,
                )
              : Icon(icon, color: Colors.grey.shade400, size: 24),
          ),
        ),
      ],
    );
  }
}