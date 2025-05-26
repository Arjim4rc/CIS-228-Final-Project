import '../helpers/biometric_helper.dart';
import 'forgot.dart';
import 'signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Student/studenthomepage.dart';
import 'Teacher/teacherhomepage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isloading = false;
  bool _obscurePassword = true;

  // Minimalistic Color Scheme
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);

  Future<void> signIn() async {
    setState(() => isloading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      final uid = userCredential.user!.uid;
      final prefs = await SharedPreferences.getInstance();

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String role = doc.data()?['role'] ?? 'student';

      await prefs.setString('uid', uid);
      await prefs.setString('userUID', uid);
      await prefs.setString('userRole', role);
      await prefs.setString('email', email.text.trim());

      role == "student"
          ? Get.offAll(() => const StudentHomepage())
          : Get.offAll(() => const TeacherHomepage());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Login Failed",
        e.message ?? e.code,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isloading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user!;
      final uid = user.uid;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      String role;
      if (!doc.exists) {
        role = await showRoleDialog(context);
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': user.email,
          'role': role,
          'name': user.displayName ?? 'Student',
          'profileImageUrl': user.photoURL ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        final data = doc.data()!;
        role = data['role'];
        if (!(data.containsKey('name') &&
            data.containsKey('profileImageUrl'))) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'name': user.displayName ?? 'Student',
            'profileImageUrl': user.photoURL ?? '',
          }, SetOptions(merge: true));
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', uid);
      await prefs.setString('userUID', uid);
      await prefs.setString('userRole', role);
      await prefs.setString('email', user.email ?? '');
      await prefs.setString('displayName', user.displayName ?? 'Student');
      if (user.photoURL != null) {
        await prefs.setString('profileImageUrl', user.photoURL!);
      }

      if (role == "student") {
        Get.offAll(() => const StudentHomepage());
      } else {
        Get.offAll(() => const TeacherHomepage());
      }
    } catch (e) {
      Get.snackbar(
        "Google Sign-In Failed",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String> showRoleDialog(BuildContext context) async {
    String selectedRole = "student";

    return await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder:
                  (context, setState) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: primaryYellow.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 30,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Select Your Role",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildRoleOption(
                            "student",
                            "Student",
                            Icons.school_outlined,
                            selectedRole,
                            (value) => setState(() => selectedRole = value!),
                          ),
                          const SizedBox(height: 12),
                          _buildRoleOption(
                            "teacher",
                            "Teacher",
                            Icons.person_outline,
                            selectedRole,
                            (value) => setState(() => selectedRole = value!),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, selectedRole);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            );
          },
        ) ??
        "student";
  }

  Widget _buildRoleOption(
    String value,
    String title,
    IconData icon,
    String groupValue,
    Function(String?) onChanged,
  ) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryBlue.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryBlue : textLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? primaryBlue : textDark,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signInWithBiometrics() async {
    final isAuthenticated = await BiometricHelper.authenticateWithBiometrics();

    if (!isAuthenticated) {
      Get.snackbar(
        "Authentication Failed",
        "Biometric authentication failed.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userUID');
    final role = prefs.getString('userRole');
    final email = prefs.getString('email');

    if (uid == null || role == null || email == null) {
      Get.snackbar(
        "Session Not Found",
        "Please login manually first.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        Get.snackbar(
          "User Not Found",
          "Please login manually.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      role == "student"
          ? Get.offAll(() => const StudentHomepage())
          : Get.offAll(() => const TeacherHomepage());
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isloading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

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
                          Icons.school,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Sign in to your account",
                        style: TextStyle(
                          fontSize: 16,
                          color: textLight,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Login Form
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
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

                          const SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Get.to(() => const Forgot()),
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "or",
                                  style: TextStyle(
                                    color: textLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Google Sign In
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: signInWithGoogle,
                              icon: const Icon(Icons.login, size: 20),
                              label: const Text("Continue with Google"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textDark,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Biometric Sign In
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: signInWithBiometrics,
                              icon: const Icon(Icons.fingerprint, size: 20),
                              label: const Text("Use Biometrics"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textDark,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Sign Up Link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: textLight, fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () => Get.to(() => const Signup()),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Sign Up",
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
