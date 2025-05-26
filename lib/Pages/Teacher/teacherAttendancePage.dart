import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/teacher_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAttendancePage extends StatelessWidget {
  final String classCode;

  const TeacherAttendancePage({super.key, required this.classCode});

  Future<int> _getTotalStudents() async {
    final studentsSnapshot =
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(classCode)
            .collection('students')
            .get();
    return studentsSnapshot.size;
  }

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
        body: FutureBuilder<int>(
          future: _getTotalStudents(),
          builder: (context, totalStudentsSnapshot) {
            if (totalStudentsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!totalStudentsSnapshot.hasData) {
              return const Center(child: Text("Failed to load student count."));
            }
            final totalStudents = totalStudentsSnapshot.data!;

            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('classes')
                      .doc(classCode)
                      .collection('attendance')
                      .orderBy(FieldPath.documentId, descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No attendance records yet."),
                  );
                }

                final attendanceDates = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: attendanceDates.length,
                  itemBuilder: (context, index) {
                    final dateDoc = attendanceDates[index];
                    final dateStr = dateDoc.id; // e.g. '2023-05-26'

                    return FutureBuilder<QuerySnapshot>(
                      future: dateDoc.reference.collection('records').get(),
                      builder: (context, recordsSnapshot) {
                        if (recordsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(
                            title: Text("Date: $dateStr"),
                            subtitle: const Text("Loading attendance data..."),
                          );
                        }

                        if (!recordsSnapshot.hasData ||
                            recordsSnapshot.data!.docs.isEmpty) {
                          return ListTile(
                            title: Text("Date: $dateStr"),
                            subtitle: const Text("No attendance data"),
                          );
                        }

                        int onTime = 0;
                        int late = 0;

                        for (var rec in recordsSnapshot.data!.docs) {
                          final data = rec.data() as Map<String, dynamic>;
                          if (data['isLate'] == true) {
                            late++;
                          } else {
                            onTime++;
                          }
                        }

                        int absent = totalStudents - (onTime + late);
                        if (absent < 0) absent = 0; // just in case

                        return ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text("Date: $dateStr"),
                          subtitle: Text(
                            "On Time: $onTime | Late: $late | Absent: $absent",
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
        bottomNavigationBar: TeacherBottomNavBar(
          currentIndex: 1,
          classCode: classCode,
        ),
      ),
    );
  }
}
