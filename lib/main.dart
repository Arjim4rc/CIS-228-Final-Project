import 'Pages/wrapper.dart';
import 'Pages/Teacher/teacherAttendancePage.dart';
import 'Pages/Teacher/teacherPeoplePage.dart';
import 'Pages/Teacher/teachersClassPage.dart';
import 'Pages/Teacher/teacherHomepage.dart'; // Make sure this file exists
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Wrapper(),
      getPages: [
        GetPage(
          name: '/teacherHomepage',
          page: () => const TeacherHomepage(), // Ensure this widget exists
        ),
        GetPage(
          name: '/teacherStream',
          page: () {
            final classCode = Get.arguments as String;
            return TeachersClassPage(classCode: classCode);
          },
        ),
        GetPage(
          name: '/teacherAttendance',
          page: () {
            final classCode = Get.arguments as String;
            return TeacherAttendancePage(classCode: classCode);
          },
        ),
        GetPage(
          name: '/teacherPeople',
          page: () {
            final classCode = Get.arguments as String;
            return TeacherPeoplePage(classCode: classCode);
          },
        ),
      ],
    );
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        
        title: Text(widget.title),
      ),
      body: Center(
        
        child: Column(
          
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

