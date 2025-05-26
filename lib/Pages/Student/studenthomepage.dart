import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../JoinClassPage.dart';
import '../../helpers/biometric_helper.dart';
import '../login.dart';
import 'StudentClassPage.dart';

class StudentHomepage extends StatefulWidget {
  const StudentHomepage({super.key});

  @override
  State<StudentHomepage> createState() => _StudentHomepageState();
}

class _StudentHomepageState extends State<StudentHomepage> {
  String email = 'Guest';
  String displayName = 'Student';
  String profileImageUrl = '';
  bool biometricEnabled = false;
  String? uid;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    uid = user?.uid;
    String nameFromFirestore = prefs.getString('displayName') ?? 'Student';
    String photoFromPrefs = prefs.getString('profileImageUrl') ?? '';
    bool biometricFromFirestore = false;

    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        nameFromFirestore = data['name'] ?? nameFromFirestore;
        photoFromPrefs = data['profileImageUrl'] ?? photoFromPrefs;
        biometricFromFirestore = data['biometricEnabled'] ?? false;
      }
    }

    setState(() {
      email = prefs.getString('email') ?? user?.email ?? 'Guest';
      displayName = nameFromFirestore;
      profileImageUrl = photoFromPrefs.isNotEmpty ? photoFromPrefs : (user?.photoURL ?? '');
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
      Get.snackbar("Failed", "Biometric authentication failed.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'student';

    await prefs.setBool('biometricEnabled', true);
    await prefs.setString('userUID', user.uid);
    await prefs.setString('userEmail', user.email ?? '');
    await prefs.setString('userRole', role);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': role,
      'biometricEnabled': true,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      biometricEnabled = true;
    });

    Get.snackbar("Success", "Biometric login enabled successfully!");
  }

  Widget buildClassCard(DocumentSnapshot classDoc) {
    final classData = classDoc.data() as Map<String, dynamic>;

    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: classData['imageUrl'] != null && classData['imageUrl'].toString().trim().isNotEmpty
              ? FadeInImage.assetNetwork(
                  placeholder: 'assets/classImage.png',
                  image: classData['imageUrl'],
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Image.asset('assets/classImage.png', height: 50, width: 50, fit: BoxFit.cover);
                  },
                )
              : Image.asset('assets/classImage.png', height: 50, width: 50, fit: BoxFit.cover),
        ),
        title: Text(classData['className'] ?? 'Unnamed Class', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Schedule: ${classData['schedule'] ?? 'N/A'}"),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
        onTap: () => Get.to(() => StudentClassPage(classCode: classData['classCode'])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              accountName: Text(displayName),
              accountEmail: Text(email),
              currentAccountPicture: CircleAvatar(
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: signOut,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(email, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                foregroundColor: Colors.black,
              ),
              onPressed: () => Get.to(() => const JoinClassPage()),
              child: const Text("Join Class"),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text("Welcome, $displayName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: biometricEnabled ? null : enableBiometricLogin,
            icon: const Icon(Icons.fingerprint),
            label: Text(biometricEnabled ? "Biometric Login Enabled" : "Enable Biometric Login"),
            style: ElevatedButton.styleFrom(
              backgroundColor: biometricEnabled ? Colors.grey : Colors.blue,
            ),
          ),
          const Divider(thickness: 1.2),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Joined Classes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('classes').get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No classes found."));
                }

                final allClassDocs = snapshot.data!.docs;

                return FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: Future.wait(
                    allClassDocs.map((classDoc) async {
                      final studentDoc = await classDoc.reference.collection('students').doc(uid).get();
                      if (studentDoc.exists) return classDoc;
                      return null;
                    }),
                  ).then((list) => list.whereType<QueryDocumentSnapshot>().toList()),
                  builder: (context, filteredSnapshot) {
                    if (filteredSnapshot.hasError) {
                      return Center(child: Text('Error: ${filteredSnapshot.error}'));
                    }
                    if (!filteredSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final joinedClasses = filteredSnapshot.data!;
                    if (joinedClasses.isEmpty) {
                      return const Center(child: Text("You haven't joined any classes yet."));
                    }

                    return ListView(
                      children: joinedClasses.map(buildClassCard).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}