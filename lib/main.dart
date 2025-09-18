import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'signup.dart'; // Import your signup page
import 'package:firebase_auth/firebase_auth.dart';

// The main entry point for your application
void main() async {
  // Ensures that Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  // Initializes Firebase
  await Firebase.initializeApp();
  // Runs the main application widget
  runApp(const MyApp());
}

// This is the root widget of your application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
      ),
      // Navigate to your SignUpPage
      home: const SignUpPage(),
    );
  }
}
