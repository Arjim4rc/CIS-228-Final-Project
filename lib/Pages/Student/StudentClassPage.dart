import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../student_nfc.dart'; // NFC attendance page for students

class StudentClassPage extends StatelessWidget {
  final String classCode;

  const StudentClassPage({super.key, required this.classCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1), // Deep blue
        foregroundColor: Colors.white,
        title: const Text("Class Details"),
        elevation: 0,
      ),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class image
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: classData['imageUrl'] != null &&
                            classData['imageUrl'].toString().startsWith('http')
                        ? Image.network(classData['imageUrl'], height: 180, fit: BoxFit.cover)
                        : Image.asset('assets/classImage.png', height: 180, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 24),

                // Class Name
                Text(
                  classData['className'] ?? 'Unnamed Class',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(height: 20),

                // Schedule
                buildInfoRow(Icons.schedule, "Schedule", classData['schedule'] ?? 'N/A', iconColor: Colors.indigo),

                const SizedBox(height: 10),

                // Class Code
                buildInfoRow(Icons.vpn_key, "Class Code", classData['classCode'] ?? 'N/A', iconColor: Colors.orange),

                const SizedBox(height: 10),

                // Teacher ID
                buildInfoRow(Icons.person, "Teacher ID", classData['teacherId'] ?? 'Unknown', iconColor: Colors.grey),

                const SizedBox(height: 30),

                // Attendance button
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.nfc),
                    label: const Text("Tap to Mark Attendance"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600), // Yellow
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentNFCPage(classCode: classCode),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                const Divider(thickness: 1),
                const SizedBox(height: 10),

                const Text(
                  '📌 Announcements / Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                const Text(
                  "This section can include class announcements or messages in the future.",
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value, {Color iconColor = Colors.black87}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
