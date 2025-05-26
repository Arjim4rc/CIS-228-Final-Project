import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeacherBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String classCode;

  const TeacherBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.classCode,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return; // Prevent unnecessary reload
        if (index == 0) {
          Get.offAllNamed('/teacherStream', arguments: classCode);
        } else if (index == 1) {
          Get.offAllNamed('/teacherAttendance', arguments: classCode);
        } else if (index == 2) {
          Get.offAllNamed('/teacherPeople', arguments: classCode);
        }
      },
      backgroundColor: const Color(0xFF0D47A1), // Deep blue background
      selectedItemColor: const Color(0xFFFFD600), // Bright yellow selected icon
      unselectedItemColor: Colors.white70,
      selectedFontSize: 14,
      unselectedFontSize: 12,
      type: BottomNavigationBarType.fixed,
      iconSize: 28,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Stream',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'People',
        ),
      ],
    );
  }
}
