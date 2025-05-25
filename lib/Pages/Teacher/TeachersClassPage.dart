import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../activate_nfc.dart';
import 'package:get/get.dart';
import '../widgets/teacher_bottom_nav.dart';

class TeachersClassPage extends StatefulWidget {
  final String classCode;

  const TeachersClassPage({super.key, required this.classCode});

  @override
  State<TeachersClassPage> createState() => _TeachersClassPageState();
}

class _TeachersClassPageState extends State<TeachersClassPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed('/teacherHomepage');
        return false;
      },
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('classes').doc(widget.classCode).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Scaffold(body: Center(child: Text("Class not found")));
          }

          final classData = snapshot.data!.data() as Map<String, dynamic>;

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Get.offAllNamed('/teacherHomepage');
                },
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      classData['className'] ?? 'Your Class',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "#${classData['classCode'] ?? ''}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: classData['imageUrl'] != null &&
                            classData['imageUrl'].toString().startsWith('http')
                        ? Image.network(classData['imageUrl'], height: 180)
                        : Image.asset('assets/classImage.png', height: 180),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '🗓 Schedule: ${classData['schedule'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '📊 Attendance Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('classes')
                        .doc(widget.classCode)
                        .collection('students')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No attendance data yet."));
                      }

                      int onTime = 0;
                      int late = 0;
                      int absent = 0;

                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        onTime += (data['onTimeCount'] ?? 0) as int;
                        late += (data['lateCount'] ?? 0) as int;
                        absent += (data['absentCount'] ?? 0) as int;
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _AttendanceStatCard(label: 'On Time', count: onTime, color: Colors.green),
                          _AttendanceStatCard(label: 'Late', count: late, color: Colors.orange),
                          _AttendanceStatCard(label: 'Absent', count: absent, color: Colors.red),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivateNFC(classCode: widget.classCode),
                          ),
                        );
                      },
                      icon: const Icon(Icons.nfc),
                      label: const Text("Activate Attendance"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '🏆 Ranking (Most On Time)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _RankingList(classCode: widget.classCode),
                ],
              ),
            ),
            bottomNavigationBar: TeacherBottomNavBar(currentIndex: 0, classCode: widget.classCode),
          );
        },
      ),
    );
  }
}

class _AttendanceStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AttendanceStatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.2),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  final String classCode;

  const _RankingList({required this.classCode});

  @override
  Widget build(BuildContext context) {
    if (classCode.isEmpty) {
      return const Center(child: Text("Invalid class code."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classCode)
          .collection('students')
          .orderBy('onTimeCount', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No ranking data yet."));
        }

        final students = snapshot.data!.docs;

        return ListView.builder(
          itemCount: students.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final data = students[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(data['name'] ?? 'Unnamed'),
              trailing: Text("✅ ${data['onTimeCount'] ?? 0} On Time"),
            );
          },
        );
      },
    );
  }
}

