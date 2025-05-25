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
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .doc(classCode)
              .collection('students')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No students joined yet."));
            }

            final students = snapshot.data!.docs;

            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(student['name'] ?? 'Unnamed'),
                  subtitle: Text(student['email'] ?? ''),
                );
              },
            );
          },
        ),
        bottomNavigationBar: TeacherBottomNavBar(currentIndex: 2, classCode: classCode),
      ),
    );
  }
}
