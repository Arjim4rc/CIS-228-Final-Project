import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/teacher_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAttendancePage extends StatelessWidget {
  final String classCode;

  const TeacherAttendancePage({super.key, required this.classCode});

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
          title: const Text('📅 Attendance Records'),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .doc(classCode)
              .collection('attendance')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No attendance records yet."));
            }

            final records = snapshot.data!.docs;

            return ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final data = records[index].data() as Map<String, dynamic>;
                final date = data['timestamp'] != null
                    ? (data['timestamp'] as Timestamp).toDate().toLocal().toString().split(' ')[0]
                    : 'Unknown';

                return ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text("Date: $date"),
                  subtitle: Text("On Time: ${data['onTime'] ?? 0} | Late: ${data['late'] ?? 0} | Absent: ${data['absent'] ?? 0}"),
                );
              },
            );
          },
        ),
        bottomNavigationBar: TeacherBottomNavBar(currentIndex: 1, classCode: classCode),
      ),
    );
  }
}
