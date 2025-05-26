import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wrapper.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController fullName = TextEditingController();
  String userRole = "student";
  bool _obscurePassword = true;
  bool isLoading = false;

  // Minimalistic Color Scheme
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);

  signup() async {
    if (fullName.text.trim().isEmpty || 
        email.text.trim().isEmpty || 
        password.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      String uid = cred.user!.uid;
      String name = fullName.text.trim();
      String profilePhotoUrl = cred.user?.photoURL ?? '';

      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email.text.trim(),
        'name': name,
        'role': userRole,
        'profileImageUrl': profilePhotoUrl,
        'biometricEnabled': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', uid);
      await prefs.setString('userUID', uid);
      await prefs.setString('userRole', userRole);
      await prefs.setString('email', email.text.trim());
      await prefs.setString('displayName', name);
      await prefs.setBool('biometricEnabled', false);
      if (profilePhotoUrl.isNotEmpty) {
        await prefs.setString('profileImageUrl', profilePhotoUrl);
      }

      Get.snackbar('Success', 'Account created successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
      
      Get.offAll(const Wrapper());
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Signup Failed', e.message ?? 'Unknown error',
          backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Signup Failed', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryBlue,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Create Account",
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Logo and Title
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: primaryYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryBlue, width: 3),
                        ),
                        child: const Icon(
                          Icons.person_add,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        "Join Us Today",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        "Create your account to get started",
                        style: TextStyle(
                          fontSize: 16,
                          color: textLight,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Signup Form
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full Name Field
                          _buildTextField(
                            controller: fullName,
                            hintText: "Full Name",
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Email Field
                          _buildTextField(
                            controller: email,
                            hintText: "Email",
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Password Field
                          _buildTextField(
                            controller: password,
                            hintText: "Password",
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: textLight,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Role Selection
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: lightGray,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.work_outline,
                                  color: textLight,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: userRole,
                                      hint: const Text(
                                        "Select Role",
                                        style: TextStyle(color: textLight, fontSize: 16),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: textDark,
                                      ),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: textLight,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: "student",
                                          child: Text("Student"),
                                        ),
                                        DropdownMenuItem(
                                          value: "teacher",
                                          child: Text("Teacher"),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            userRole = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Signup Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Terms and Privacy
                          Text(
                            "By creating an account, you agree to our Terms of Service and Privacy Policy",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: textLight,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Login Link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: textLight,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.back(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: textDark),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: textLight, fontSize: 16),
          prefixIcon: Icon(icon, color: textLight, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}