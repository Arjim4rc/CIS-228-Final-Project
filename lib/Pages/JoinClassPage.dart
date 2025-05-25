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
      Get.snackbar("Invalid", "Please enter a valid 4-digit class code.");
      return;
    }

    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = FirebaseAuth.instance.currentUser;

    try {
      final doc = await FirebaseFirestore.instance.collection('classes').doc(code).get();

      if (!doc.exists) {
        Get.snackbar("Error", "Class not found.");
        return;
      }

      final studentRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(code)
          .collection('students')
          .doc(uid);

      final studentExists = await studentRef.get();
      if (studentExists.exists) {
        Get.snackbar("Info", "You already joined this class.");
        return;
      }

      await studentRef.set({
        'studentId': uid,
        'name': user?.displayName ?? '',
        'email': user?.email ?? '',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      Get.back(); // Return to previous screen
      Get.snackbar("Success", "Class joined successfully!");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Class")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Enter 4-digit Class Code",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : joinClass,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Join Class"),
            ),
          ],
        ),
      ),
    );
  }
}
