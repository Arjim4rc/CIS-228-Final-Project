import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../widgets/teacher_bottom_nav.dart';

class TeacherPeoplePage extends StatelessWidget {
  final String classCode;

  const TeacherPeoplePage({super.key, required this.classCode});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed('/teacherHomepage');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.offAllNamed('/teacherHomepage'),
          ),
          title: const Text("👥 Class Members"),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: const Color(0xFFE3F2FD), // Light blue background
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .doc(classCode)
              .collection('students')
              .orderBy('joinedAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No students joined yet.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            final students = snapshot.data!.docs;

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: students.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final student = students[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1976D2),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    student['name'] ?? 'Unnamed',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(student['email'] ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );
              },
            );
          },
        ),
        bottomNavigationBar:
            TeacherBottomNavBar(currentIndex: 2, classCode: classCode),
      ),
    );
  }
}
