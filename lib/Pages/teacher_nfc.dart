import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherNFCPage extends StatefulWidget {
  final String classCode;

  const TeacherNFCPage({super.key, required this.classCode});

  @override
  State<TeacherNFCPage> createState() => _TeacherNFCPageState();
}

class _TeacherNFCPageState extends State<TeacherNFCPage> {
  bool isNfcActive = false;
  TimeOfDay? lateThreshold;
  Set<String> tappedNfcIds = {};
  String statusMessage = 'Tap student phones to mark attendance...';

  int onTimeCount = 0;
  int lateCount = 0;

  void startNfcSession() async {
    if (lateThreshold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a late threshold time first.'),
        ),
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
        final nfcId = tag.id.toUpperCase();

        // Check if already tapped BEFORE doing anything else
        if (tappedNfcIds.contains(nfcId)) {
          setState(() => statusMessage = 'Already marked: $nfcId');
          await FlutterNfcKit.finish();

          // Add a delay to prevent immediate re-polling of the same tag
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
        }

        // Check if student exists in database
        final userSnap =
            await FirebaseFirestore.instance
                .collection('users')
                .where('nfcId', isEqualTo: nfcId)
                .limit(1)
                .get();

        if (userSnap.docs.isEmpty) {
          await FlutterNfcKit.finish();
          setState(() => statusMessage = 'No student found for tag: $nfcId');
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
        }

        final studentDoc = userSnap.docs.first;
        final studentId = studentDoc.id;
        final studentName = studentDoc['name'] ?? 'Unknown';

        // Check if student already has attendance for today
        final dateKey = _getTodayDateKey();
        final existingRecord =
            await FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classCode)
                .collection('attendance')
                .doc(dateKey)
                .collection('records')
                .doc(studentId)
                .get();

        if (existingRecord.exists) {
          await FlutterNfcKit.finish();
          setState(
            () =>
                statusMessage = 'Attendance already recorded for: $studentName',
          );
          // Add this NFC ID to prevent re-processing
          tappedNfcIds.add(nfcId);
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
        }

        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Confirm Attendance'),
                content: Text(
                  'Mark attendance for:\n\n$studentName\nID: $studentId',
                ),
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

        await FlutterNfcKit.finish();

        if (confirm != true) {
          setState(() => statusMessage = 'Cancelled: $studentName');
          await Future.delayed(const Duration(milliseconds: 1000));
          continue;
        }

        final now = DateTime.now();
        final threshold = DateTime(
          now.year,
          now.month,
          now.day,
          lateThreshold!.hour,
          lateThreshold!.minute,
        );
        final isLate = now.isAfter(threshold);

        // Mark as tapped BEFORE recording to prevent race conditions
        tappedNfcIds.add(nfcId);

        try {
          await _recordAttendance(studentId, studentName, now, isLate);

          final formattedTime =
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

          setState(() {
            if (isLate) {
              lateCount++;
              statusMessage = 'Late: $studentName at $formattedTime';
            } else {
              onTimeCount++;
              statusMessage = 'On-time: $studentName at $formattedTime';
            }
          });
        } catch (e) {
          // If recording fails, remove from tapped set so they can try again
          tappedNfcIds.remove(nfcId);
          setState(
            () =>
                statusMessage =
                    'Failed to record attendance for $studentName: $e',
          );
        }

        // Add delay to prevent immediate re-polling
        await Future.delayed(const Duration(milliseconds: 1500));
      } catch (e) {
        setState(() => statusMessage = 'NFC Error: $e');
        await FlutterNfcKit.finish();
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
  }

  String _getTodayDateKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _recordAttendance(
    String studentId,
    String name,
    DateTime timestamp,
    bool isLate,
  ) async {
    final classRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classCode);
    final dateKey = _getTodayDateKey();

    await classRef
        .collection('attendance')
        .doc(dateKey)
        .collection('records')
        .doc(studentId)
        .set({
          'studentId': studentId,
          'studentName': name,
          'timestamp': timestamp,
          'isLate': isLate,
        }, SetOptions(merge: true));
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
            Text(
              'Class Code: ${widget.classCode}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Late After: '),
                ElevatedButton(
                  onPressed: pickLateTime,
                  child: Text(
                    lateThreshold != null
                        ? lateThreshold!.format(context)
                        : 'Select Time',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            Text(statusMessage, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (!isNfcActive)
              Text(
                "Summary:\n- On Time: $onTimeCount\n- Late: $lateCount",
                style: const TextStyle(fontSize: 15),
              ),
          ],
        ),
      ),
    );
  }
}
