import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
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

  int onTimeCount = 0;
  int lateCount = 0;
  int absentCount = 0;

  String statusMessage = 'Tap student phones to mark attendance...';

  Set<String> tappedStudentIds = {};

  @override
  void dispose() {
    if (isNfcActive) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  void pickLateTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        lateThreshold = picked;
      });
    }
  }

  void startNfcSession() {
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
      onTimeCount = 0;
      lateCount = 0;
      absentCount = 0;
      tappedStudentIds.clear();
      statusMessage = 'NFC Activated. Waiting for taps...';
    });

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          // Use NfcA wrapper to access identifier safely
          final nfcA = NfcA.from(tag);
          if (nfcA == null) {
            setState(() => statusMessage = 'NFC-A tag not found.');
            return;
          }

          final identifier = nfcA.identifier;
          if (identifier == null || identifier.isEmpty) {
            setState(() => statusMessage = 'Tag identifier not found.');
            return;
          }

          final studentId =
              identifier
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join()
                  .toUpperCase();

          if (tappedStudentIds.contains(studentId)) {
            setState(
              () =>
                  statusMessage =
                      'Student $studentId already marked attendance.',
            );
            return;
          }

          tappedStudentIds.add(studentId);

          DateTime now = DateTime.now();
          DateTime lateThresholdDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            lateThreshold!.hour,
            lateThreshold!.minute,
          );

          bool isLate = now.isAfter(lateThresholdDateTime);

          await _saveAttendanceRecord(studentId, now, isLate);

          setState(() {
            if (isLate) {
              lateCount++;
              statusMessage = 'Late attendance marked for student $studentId.';
            } else {
              onTimeCount++;
              statusMessage =
                  'On-time attendance marked for student $studentId.';
            }
          });
        } catch (e) {
          setState(() => statusMessage = 'Error reading tag: $e');
        }
      },
    );
  }

  Future<void> _saveAttendanceRecord(
    String studentId,
    DateTime timestamp,
    bool isLate,
  ) async {
    final classDoc = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classCode);
    final attendanceCollection = classDoc.collection('attendance');

    final dateStr = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    ).toIso8601String().substring(0, 10);

    final dayAttendanceDoc = attendanceCollection.doc(dateStr);
    final studentAttendanceDoc = dayAttendanceDoc
        .collection('records')
        .doc(studentId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final dayDocSnapshot = await transaction.get(dayAttendanceDoc);
      if (!dayDocSnapshot.exists) {
        transaction.set(dayAttendanceDoc, {
          'date': dateStr,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(studentAttendanceDoc, {
        'studentId': studentId,
        'timestamp': timestamp,
        'isLate': isLate,
      });
    });
  }

  void stopNfcSession() {
    NfcManager.instance.stopSession();
    setState(() {
      isNfcActive = false;
      statusMessage = 'NFC Deactivated. You can save or discard attendance.';
    });
  }

  void saveAttendance() {
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Attendance saved.")));
  }

  void discardAttendance() {
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Attendance discarded.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Activate Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📘 Class Code: ${widget.classCode}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Text("⏰ Late After: ", style: TextStyle(fontSize: 16)),
                ElevatedButton(
                  onPressed: pickLateTime,
                  child: Text(
                    lateThreshold != null
                        ? lateThreshold!.format(context)
                        : "Select Time",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            isNfcActive
                ? ElevatedButton.icon(
                  icon: const Icon(Icons.stop_circle),
                  label: const Text("Deactivate NFC"),
                  onPressed: stopNfcSession,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                )
                : ElevatedButton.icon(
                  icon: const Icon(Icons.nfc),
                  label: const Text("Activate NFC"),
                  onPressed: startNfcSession,
                ),

            const SizedBox(height: 30),

            Text(statusMessage, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 20),

            if (!isNfcActive) ...[
              Row(
                children: [
                  ElevatedButton(
                    onPressed: saveAttendance,
                    child: const Text("✅ Save"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: discardAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text("❌ Discard"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Summary:\n"
                "- On Time: $onTimeCount\n"
                "- Late: $lateCount\n"
                "- Absent: $absentCount\n",
              ),
            ],
          ],
        ),
      ),
    );
  }
}
