import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isDoctor = false;
  bool isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1️⃣ Logic: Load Data
  void _loadUserData() async {
    if (user == null) return;
    try {
      var docSnap = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

      if (docSnap.exists) {
        var data = docSnap.data();
        String role = data?['role'] ?? 'patient';
        if (mounted) {
          setState(() {
            isDoctor = role == 'doctor';
            _nameController.text = data?['name'] ?? "";
            _bioController.text = data?['about'] ?? "";
            _specialtyController.text = data?['specialty'] ?? "";
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 2️⃣ Logic: Update Profile
  void _updateProfile() async {
    if (user == null) return;
    
    setState(() => isLoading = true); 

    try {
      Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
      };

      if (isDoctor) {
        data['about'] = _bioController.text.trim();
        data['specialty'] = _specialtyController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update(data);
      
      if (mounted) {
         setState(() => isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(backgroundColor: Colors.green, content: Text("Profile Updated Successfully!"))
         );
      }
    } catch (e) {
       if (mounted) {
         setState(() => isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(backgroundColor: Colors.red, content: Text("Error: $e"))
         );
       }
    }
  }

  // 3️⃣ Logic: Delete Account
  void _deleteAccount() async {
    if (user == null) return;

    try {
      // Optional: Delete user data from Firestore first
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();

      // Delete Authentication User
      await user!.delete();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()), 
          (route) => false
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please log out and log in again to delete your account."))
            );
         }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
         }
      }
    } catch (e) {
      debugPrint("Error deleting account: $e");
    }
  }

  // 4️⃣ Logic: Logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Navigate to root (AuthWrapper will automatically show GuestHomeScreen)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  // Confirmation Dialog
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure? This cannot be undone and you will lose all your data."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              _deleteAccount(); 
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF407CE2),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 30),

            _buildTextField("Full Name", _nameController, Icons.person),
            const SizedBox(height: 15),

            if (isDoctor) ...[
              _buildTextField("Specialty", _specialtyController, Icons.work),
              const SizedBox(height: 15),
              _buildTextField("About (Bio)", _bioController, Icons.info, maxLines: 3),
              const SizedBox(height: 15),
            ],

            const SizedBox(height: 40),
            
            // --- Delete Button (Solid Red) ---
            SizedBox(
              width: double.infinity,
              height: 55, 
              child: ElevatedButton(
                onPressed: _showDeleteConfirmDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935), // Solid Red Color
                  foregroundColor: Colors.white, // White Text & Icon
                  elevation: 2, // Shadow
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Delete Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    //Icon(Icons.delete_forever, color: Colors.white), // White Icon
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --- Save Button (Solid Blue) ---
            SizedBox(
              width: double.infinity,
              height: 55, 
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF407CE2), // Solid Blue
                  foregroundColor: Colors.white, // White Text
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}