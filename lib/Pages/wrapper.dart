import 'Student/studenthomepage.dart';
import 'Teacher/teacherhomepage.dart';
import 'login.dart';
import 'verifyemail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // <-- add this

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
    } catch (e) {
      // Handle error or return null if something goes wrong
    }
    return null;
  }

  Future<Widget> getRedirectWidget(User user) async {
    if (!user.emailVerified) return const Verify();

    String? role = await getUserRole(user.uid);

    if (role == "student") return const StudentHomepage();
    if (role == "teacher") return const TeacherHomepage();

    return const Login(); // fallback if role not found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<Widget>(
              future: getRedirectWidget(snapshot.data!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return snapshot.data ?? const Login();
              },
            );
          } else {
            return const Login();
          }
        },
      ),
    );
  }
}
