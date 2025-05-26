import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/biometric_helper.dart';
import '../login.dart';
import 'TeachersClassPage.dart';
import '../CreateClassPage.dart';

class TeacherHomepage extends StatefulWidget {
  const TeacherHomepage({super.key});

  @override
  State<TeacherHomepage> createState() => _TeacherHomepageState();
}

class _TeacherHomepageState extends State<TeacherHomepage> {
  String email = 'Guest';
  String displayName = 'Teacher';
  String profileImageUrl = '';
  bool biometricEnabled = false;
  String? uid;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color lightYellow = Color(0xFFFEF3C7);
  static const Color darkBlue = Color(0xFF1E40AF);
  static const Color softGray = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    uid = user?.uid;

    String nameFromPrefs = prefs.getString('displayName') ?? 'Teacher';
    String photoFromPrefs = prefs.getString('profileImageUrl') ?? '';
    bool biometricFromFirestore = false;

    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        nameFromPrefs = data['name'] ?? nameFromPrefs;
        photoFromPrefs = data['profileImageUrl'] ?? photoFromPrefs;
        biometricFromFirestore = data['biometricEnabled'] ?? false;
      }
    }

    setState(() {
      email = prefs.getString('email') ?? user?.email ?? 'Guest';
      displayName = nameFromPrefs;
      profileImageUrl = user?.photoURL ?? photoFromPrefs;
      biometricEnabled = biometricFromFirestore;
    });

    await prefs.setString('email', email);
    await prefs.setString('displayName', displayName);
    if (profileImageUrl.isNotEmpty) {
      await prefs.setString('profileImageUrl', profileImageUrl);
    }
    await prefs.setBool('biometricEnabled', biometricEnabled);
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const Login());
  }

  Future<void> enableBiometricLogin() async {
    bool isAuthenticated = await BiometricHelper.authenticateWithBiometrics();
    if (!isAuthenticated) {
      Get.snackbar(
        "Failed",
        "Biometric authentication failed.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'teacher';

    await prefs.setBool('biometricEnabled', true);
    await prefs.setString('userUID', uid);
    await prefs.setString('userEmail', user.email ?? '');
    await prefs.setString('userRole', role);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': user.email,
      'role': role,
      'biometricEnabled': true,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      biometricEnabled = true;
    });

    Get.snackbar(
      "Success",
      "Biometric login enabled successfully!",
      backgroundColor: lightYellow,
      colorText: darkBlue,
    );
  }

  Widget buildClassCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, lightYellow.withOpacity(0.1)],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: lightBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Get.to(() => TeachersClassPage(classCode: data['classCode']));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [lightBlue, primaryBlue],
                    ),
                  ),
                  child: const Icon(Icons.class_, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['className'] ?? 'Unnamed Class',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            "Schedule: ${data['schedule'] ?? 'N/A'}",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: primaryBlue, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGray,
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryBlue, lightBlue],
            ),
          ),
          child: ListView(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                      radius: 30,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text("Logout", style: TextStyle(color: Colors.white)),
                onTap: signOut,
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, lightBlue],
            ),
          ),
        ),
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
                radius: 18,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(email, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: accentYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const CreateClassPage()),
                icon: const Icon(Icons.add, color: primaryBlue),
                label: const Text("Create Class",
                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, lightYellow.withOpacity(0.3)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text("Welcome back,", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(displayName,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: primaryBlue)),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: biometricEnabled
                                ? LinearGradient(colors: [Colors.green[100]!, Colors.green[50]!])
                                : LinearGradient(colors: [lightBlue, primaryBlue]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: biometricEnabled ? null : enableBiometricLogin,
                            icon: Icon(Icons.fingerprint,
                                color: biometricEnabled ? Colors.green[700] : Colors.white),
                            label: Text(
                              biometricEnabled
                                  ? "Biometric Login Enabled"
                                  : "Enable Biometric Login",
                              style: TextStyle(
                                color: biometricEnabled ? Colors.green[700] : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: accentYellow,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Your Classes",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('classes')
                        .where('teacherId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Error loading classes.'));
                      } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No classes created yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      return Column(
                        children:
                            snapshot.data!.docs.map((doc) => buildClassCard(doc)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
