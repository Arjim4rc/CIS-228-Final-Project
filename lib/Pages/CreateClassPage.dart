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
      Get.snackbar("Error", "Please fill all required fields",
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
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
        'imageUrl': 'assets/classImage.png', // Default class image
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.back(); // Return to previous screen
      Get.snackbar("Success", "Class created with code: $classCode",
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
        title: const Text("Create Class"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Class Name Field
            TextField(
              controller: classNameController,
              decoration: InputDecoration(
                labelText: "Class Name",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.class_),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Schedule Field
            TextField(
              controller: scheduleController,
              decoration: InputDecoration(
                labelText: "Schedule",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.schedule),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Class Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/classImage.png', height: 150, fit: BoxFit.cover),
            ),
            const SizedBox(height: 30),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Create Class"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD600), // Yellow button
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : createClass,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
