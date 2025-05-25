import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassDetailsPage extends StatelessWidget {
  final String classCode;

  const ClassDetailsPage({super.key, required this.classCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Class Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('classes').doc(classCode).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("An error occurred. Please try again."));
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: classData['imageUrl'] != null &&
                            classData['imageUrl'].toString().startsWith('http')
                        ? Image.network(classData['imageUrl'], height: 180, width: double.infinity, fit: BoxFit.cover)
                        : Image.asset('assets/classImage.png', height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),

                const SizedBox(height: 20),

                // Class Name
                Text(
                  classData['className'] ?? 'Unnamed Class',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // Schedule
                Text(
                  '🗓 Schedule: ${classData['schedule'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 10),

                // Class Code
                Text(
                  '🆔 Class Code: ${classData['classCode'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 10),

                // Teacher ID
                Text(
                  '👨‍🏫 Teacher ID: ${classData['teacherId'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 30),
                const Divider(),

                // Placeholder for Enrolled Students
                const Text(
                  'Enrolled Students:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text("Coming soon..."),
              ],
            ),
          );
        },
      ),
    );
  }
}
