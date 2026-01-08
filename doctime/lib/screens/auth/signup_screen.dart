import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool isDoctor = false;

  // 2. دالة التسجيل (تم التعديل لحل مشكلة الشاشة السوداء)
  void handleSignup() async {
    // فحوصات الأمان (Validation)
    if (passwordController.text != confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (isDoctor) {
      if (specialtyController.text.trim().isEmpty ||
          locationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all doctor fields!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      // 1️⃣ إنشاء المستخدم في Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      // 2️⃣ تجهيز البيانات حسب النوع (دكتور أو مريض)
      String collectionName = isDoctor ? 'doctors' : 'users';

      Map<String, dynamic> userData = {
        'uid': uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': isDoctor ? 'doctor' : 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (isDoctor) {
        userData['specialty'] = specialtyController.text.trim();
        userData['location'] = locationController.text.trim();
        userData['bio'] = ''; // حقل فاضي عشان ما يعطي Error بالبروفايل
      }

      // 3️⃣ حفظ البيانات في Firestore (أهم نقطة: AWAIT)
      // لازم نستنى هاي الخطوة تخلص قبل ما نعمل أي شي
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .set(userData);

      // 4️⃣ بعد ما تأكدنا إنو الحفظ تم، بنطلع من الصفحة
      if (mounted) {
        // بنعمل تسجيل خروج عشان نضمن إنو اليوزر يدخل من صفحة اللوجين وتتحمل بياناته صح
        await FirebaseAuth.instance.signOut();

        setState(() => isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );

        // الرسالة بتطلع للمستخدم وهو في صفحة اللوجين
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully! Please Login with your new account.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        String message = "An error occurred";
        if (e.code == 'email-already-in-use') {
          message = "The email is already in use.";
        } else if (e.code == 'weak-password') {
          message = "The password is too weak.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Sign up",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: primaryBlue,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Create your new account",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 30),

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
                  onEyeTap: () =>
                      setState(() => isObscurePass = !isObscurePass),
                ),

                const SizedBox(height: 20),

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
                  onEyeTap: () =>
                      setState(() => isObscureConfirm = !isObscureConfirm),
                ),

                const SizedBox(height: 25),

                // سويتش الدكتور
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDoctor
                        ? primaryBlue.withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDoctor ? primaryBlue : borderColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        color: isDoctor ? primaryBlue : Colors.grey,
                      ),
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
                        activeThumbColor: primaryBlue,
                        onChanged: (val) => setState(() => isDoctor = val),
                      ),
                    ],
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  reverseDuration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1.0,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                  child: isDoctor
                      ? Column(
                          key: const ValueKey('doctor_fields'),
                          children: [
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
                              hint: "e.g. Amman, Irbid",
                              icon: Icons.location_on_outlined,
                              borderColor: borderColor,
                              primaryBlue: primaryBlue,
                              labelColor: labelColor,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign Up",
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPass ? isObscure : false,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
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
            suffixIcon: isPass
                ? IconButton(
                    icon: Icon(
                      isObscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
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
