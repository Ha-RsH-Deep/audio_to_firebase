import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final log = Logger('MyApp');


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.microphone.request();
  await _initializeFirebase();
  runApp(const MyApp());
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}


_initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize Firestore
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
}




