import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'wrapper.dart';

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  bool _emailSent = false;
  bool _sentLink = false;

  @override
  void initState() {
    super.initState();
    if (!_sentLink) {
      sendverifylink();
      _sentLink = true;
    }
  }

  sendverifylink() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.reload(); // make sure we have the latest status
    if (!user.emailVerified && !_emailSent) {
      await user.sendEmailVerification();
      setState(() {
        _emailSent = true;
      });
      Get.snackbar(
        'Link sent',
        'Check your email for the verification link',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  reload() async {
    await FirebaseAuth.instance.currentUser!.reload();
    final user = FirebaseAuth.instance.currentUser!;
    if (user.emailVerified) {
      Get.offAll(() => const Wrapper());
    } else {
      Get.snackbar(
        'Not Verified',
        'Please verify your email first',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verification")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "Open your mail and click on the link provided to verify your email.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: reload,
                child: const Text("Reload"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
