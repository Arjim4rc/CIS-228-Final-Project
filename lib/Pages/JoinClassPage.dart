import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JoinClassPage extends StatefulWidget {
  const JoinClassPage({super.key});

  @override
  State<JoinClassPage> createState() => _JoinClassPageState();
}

class _JoinClassPageState extends State<JoinClassPage> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;

  Future<void> joinClass() async {
    final code = codeController.text.trim();
    if (code.length != 4) {
      Get.snackbar("Invalid", "Please enter a valid 4-digit class code.",
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
      return;
    }

    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = FirebaseAuth.instance.currentUser;

    try {
      final doc = await FirebaseFirestore.instance.collection('classes').doc(code).get();

      if (!doc.exists) {
        Get.snackbar("Error", "Class not found.",
            backgroundColor: Colors.red.shade100, colorText: Colors.black);
        return;
      }

      final studentRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(code)
          .collection('students')
          .doc(uid);

      final studentExists = await studentRef.get();
      if (studentExists.exists) {
        Get.snackbar("Info", "You already joined this class.",
            backgroundColor: Colors.yellow.shade100, colorText: Colors.black);
        return;
      }

      await studentRef.set({
        'studentId': uid,
        'name': user?.displayName ?? '',
        'email': user?.email ?? '',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      Get.back(); // Return to previous screen
      Get.snackbar("Success", "Class joined successfully!",
          backgroundColor: Colors.green.shade100, colorText: Colors.black);
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF), // Light blue background
      appBar: AppBar(
        title: const Text("Join Class"),
        backgroundColor: const Color(0xFF0D47A1), // Dark blue
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Class Code Input
            TextField(
              controller: codeController,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter 4-digit Class Code",
                prefixIcon: const Icon(Icons.vpn_key),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),

            // Join Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.group_add),
                label: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Join Class"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD600), // Yellow
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : joinClass,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
