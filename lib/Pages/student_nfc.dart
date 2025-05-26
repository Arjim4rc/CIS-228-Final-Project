import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentNFCPage extends StatefulWidget {
  final String classCode;

  const StudentNFCPage({super.key, required this.classCode});

  @override
  State<StudentNFCPage> createState() => _StudentNFCPageState();
}

class _StudentNFCPageState extends State<StudentNFCPage> {
  String statusMessage = 'Press Activate to mark attendance.';
  bool isActivated = false;
  bool isMarked = false;

  Future<void> activateAttendance() async {
    setState(() {
      statusMessage = 'Attendance activated. Press Deactivate to confirm.';
      isActivated = true;
    });
  }

  Future<void> deactivateAndMarkAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => statusMessage = 'User not logged in.');
      return;
    }

    final uid = user.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('students').doc(uid).get();
    final studentName = userDoc['name'] ?? 'Unknown';

    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final recordRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classCode)
        .collection('attendance')
        .doc(dateStr)
        .collection('records')
        .doc(uid);

    final existingRecord = await recordRef.get();
    if (existingRecord.exists) {
      setState(() {
        statusMessage = 'You already marked attendance today!';
        isMarked = true;
      });
      return;
    }

    await recordRef.set({
      'studentId': uid,
      'studentName': studentName,
      'timestamp': now,
      'isLate': false, // Adjusted by teacher after review
    });

    setState(() {
      statusMessage = 'Attendance marked successfully!';
      isMarked = true;
      isActivated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(statusMessage, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            if (!isActivated && !isMarked)
              ElevatedButton.icon(
                onPressed: activateAttendance,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Activate'),
              ),
            if (isActivated && !isMarked)
              ElevatedButton.icon(
                onPressed: deactivateAndMarkAttendance,
                icon: const Icon(Icons.stop),
                label: const Text('Deactivate'),
              ),
            if (isMarked)
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
          ],
        ),
      ),
    );
  }
}
