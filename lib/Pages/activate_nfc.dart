/*import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivateNFC extends StatefulWidget {
  final String classCode;

  const ActivateNFC({super.key, required this.classCode});

  @override
  State<ActivateNFC> createState() => _ActivateNFCState();
}

class _ActivateNFCState extends State<ActivateNFC> {
  bool isNfcActive = false;
  TimeOfDay? lateThreshold;
  Set<String> tappedStudentIds = {};
  String statusMessage = 'Tap student phones to mark attendance...';

  int onTimeCount = 0;
  int lateCount = 0;

  void startNfcSession() async {
  if (lateThreshold == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a late threshold time first.')),
    );
    return;
  }

  setState(() {
    isNfcActive = true;
    statusMessage = 'NFC Activated. Waiting for taps...';
  });

  while (isNfcActive) {
    try {
      final tag = await FlutterNfcKit.poll();
      final studentId = tag.id.toUpperCase(); // NFC tag UID as uppercase hex

      if (tappedStudentIds.contains(studentId)) {
        setState(() => statusMessage = 'Already marked: $studentId');
        await FlutterNfcKit.finish();
        continue;
      }

      // ✅ Ask for confirmation before marking attendance
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm Tag'),
          content: Text('Confirm attendance for student ID:\n\n$studentId'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      await FlutterNfcKit.finish(); // Make sure session is finished before looping

      if (confirm != true) {
        setState(() => statusMessage = 'Cancelled: $studentId');
        continue;
      }

      tappedStudentIds.add(studentId);

      final now = DateTime.now();
      final threshold = DateTime(
        now.year,
        now.month,
        now.day,
        lateThreshold!.hour,
        lateThreshold!.minute,
      );

      final isLate = now.isAfter(threshold);
      await _saveAttendanceRecord(studentId, now, isLate);

      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      setState(() {
        if (isLate) {
          lateCount++;
          statusMessage = 'Late: $studentId at $timeStr';
        } else {
          onTimeCount++;
          statusMessage = 'On-time: $studentId at $timeStr';
        }
      });
    } catch (e) {
      setState(() => statusMessage = 'Error: $e');
      await FlutterNfcKit.finish();
    }
  }
}


  Future<void> _saveAttendanceRecord(String studentId, DateTime timestamp, bool isLate) async {
    final classDoc = FirebaseFirestore.instance.collection('classes').doc(widget.classCode);
    final attendanceCollection = classDoc.collection('attendance');

    final dateStr = "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";

    await attendanceCollection.doc(dateStr).collection('records').doc(studentId).set({
      'studentId': studentId,
      'timestamp': timestamp,
      'isLate': isLate,
    });
  }

  void stopNfcSession() {
    setState(() {
      isNfcActive = false;
      statusMessage = 'NFC Deactivated.';
    });
  }

  void pickLateTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => lateThreshold = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activate Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class Code: ${widget.classCode}'),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Late After: '),
                ElevatedButton(
                  onPressed: pickLateTime,
                  child: Text(lateThreshold != null ? lateThreshold!.format(context) : 'Select Time'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            isNfcActive
                ? ElevatedButton.icon(
                    onPressed: stopNfcSession,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop NFC'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  )
                : ElevatedButton.icon(
                    onPressed: startNfcSession,
                    icon: const Icon(Icons.nfc),
                    label: const Text('Start NFC'),
                  ),
            const SizedBox(height: 20),
            Text(statusMessage),
            const SizedBox(height: 10),
            if (!isNfcActive) ...[
              Text("Summary:\n- On Time: $onTimeCount\n- Late: $lateCount"),
            ],
          ],
        ),
      ),
    );
  }
}*/