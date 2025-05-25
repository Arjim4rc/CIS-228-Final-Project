import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../activate_nfc.dart';  // Make sure this import path is correct

class StudentClassPage extends StatelessWidget {
  final String classCode;

  const StudentClassPage({super.key, required this.classCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Class Info")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('classes').doc(classCode).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Class not found"));
          }

          final classData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Image
                Center(
                  child: classData['imageUrl'] != null &&
                          classData['imageUrl'].toString().startsWith('http')
                      ? Image.network(classData['imageUrl'], height: 180)
                      : Image.asset('assets/classImage.png', height: 180),
                ),

                const SizedBox(height: 20),

                // Class Name
                Text(
                  classData['className'] ?? 'Unnamed Class',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // Schedule
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      classData['schedule'] ?? 'N/A',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Class Code
                Row(
                  children: [
                    const Icon(Icons.vpn_key, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      classData['classCode'] ?? 'N/A',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Teacher Info
                Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Teacher ID: ${classData['teacherId'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Activate Attendance Button for students (for testing NFC tap)
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.nfc),
                    label: const Text("Activate Attendance"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivateNFC(classCode: classCode),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                const Divider(),
                const Text(
                  '📌 Announcements / Notes:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text("This section can include class announcements or messages in the future."),
              ],
            ),
          );
        },
      ),
    );
  }
}
