import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateClassPage extends StatefulWidget {
  const CreateClassPage({super.key});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController scheduleController = TextEditingController();
  bool isLoading = false;

  String generateClassCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString(); // 4-digit class code
  }

  Future<void> createClass() async {
    if (classNameController.text.isEmpty || scheduleController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all required fields");
      return;
    }

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    final classCode = generateClassCode();

    try {
      await FirebaseFirestore.instance.collection('classes').doc(classCode).set({
        'className': classNameController.text.trim(),
        'schedule': scheduleController.text.trim(),
        'teacherId': user!.uid,
        'teacherEmail': user.email,
        'classCode': classCode,
        'imageUrl': 'assets/classImage.png', // Default image path
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.back(); // Return to previous screen (e.g., TeacherHomepage)
      Get.snackbar("Success", "Class created with code: $classCode");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Class")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: classNameController,
              decoration: const InputDecoration(labelText: "Class Name"),
            ),
            TextField(
              controller: scheduleController,
              decoration: const InputDecoration(labelText: "Schedule"),
            ),
            const SizedBox(height: 10),
            Image.asset('assets/classImage.png', height: 150),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : createClass,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Class"),
            ),
          ],
        ),
      ),
    );
  }
}
