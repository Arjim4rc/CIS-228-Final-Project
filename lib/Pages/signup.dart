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
  String userRole = "student"; // default role

  signup() async {
    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      String uid = cred.user!.uid;
      String name = fullName.text.trim();
      String profilePhotoUrl = cred.user?.photoURL ?? ''; // May be null

      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email.text.trim(),
        'name': name,
        'role': userRole,
        'profileImageUrl': profilePhotoUrl,
        'biometricEnabled': false, // 👈 Set explicitly
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

      Get.offAll(const Wrapper());
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Signup Failed', e.message ?? 'Unknown error');
    } catch (e) {
      Get.snackbar('Signup Failed', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: fullName,
              decoration: const InputDecoration(hintText: 'Enter full name'),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(hintText: 'Enter email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Enter password'),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: userRole,
              items: const [
                DropdownMenuItem(value: "student", child: Text("Student")),
                DropdownMenuItem(value: "teacher", child: Text("Teacher")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    userRole = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: signup, child: const Text("Sign Up")),
          ],
        ),
      ),
    );
  }
}
