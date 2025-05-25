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

      // Fetch role from Firestore
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
      Get.snackbar("Login Failed", e.message ?? e.code);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => isloading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Show account picker
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
        // Optionally refresh name/photo if missing
        if (!(data.containsKey('name') && data.containsKey('profileImageUrl'))) {
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

      // ✅ Add these lines to show profile picture and name
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
      Get.snackbar("Google Sign-In Failed", e.toString());
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
                  (context, setState) => AlertDialog(
                    title: const Text("Select your role"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          value: "student",
                          groupValue: selectedRole,
                          title: const Text("Student"),
                          onChanged:
                              (value) => setState(() => selectedRole = value!),
                        ),
                        RadioListTile<String>(
                          value: "teacher",
                          groupValue: selectedRole,
                          title: const Text("Teacher"),
                          onChanged:
                              (value) => setState(() => selectedRole = value!),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, selectedRole);
                          },
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  ),
            );
          },
        ) ??
        "student";
  }

  Future<void> signInWithBiometrics() async {
    final isAuthenticated = await BiometricHelper.authenticateWithBiometrics();

    if (!isAuthenticated) {
      Get.snackbar("Failed", "Biometric authentication failed.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userUID');
    final role = prefs.getString('userRole');
    final email = prefs.getString('email');

    if (uid == null || role == null || email == null) {
      Get.snackbar(
        "Error",
        "Biometric matched, but no saved session found. Please login manually.",
      );
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        Get.snackbar(
          "Error",
          "User not found in Firestore. Please login manually.",
        );
        return;
      }

      role == "student"
          ? Get.offAll(() => const StudentHomepage())
          : Get.offAll(() => const TeacherHomepage());
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return isloading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
          appBar: AppBar(title: const Text("Login")),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextField(
                  controller: email,
                  decoration: const InputDecoration(hintText: 'Enter email'),
                ),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Enter password'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: signIn, child: const Text("Login")),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text("Sign in with Google"),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: signInWithBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text("Login with Biometrics"),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Get.to(() => const Signup()),
                  child: const Text("Register now"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Get.to(() => const Forgot()),
                  child: const Text("Forgot password"),
                ),
              ],
            ),
          ),
        );
  }
}
