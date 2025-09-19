import 'package:cp_final/login.dart';
import 'package:cp_final/service/auth.dart';
import 'package:flutter/material.dart';

class ReaderDashboard extends StatelessWidget {
  const ReaderDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader Dashboard'),
        backgroundColor: Colors.blueAccent, // A different color for distinction
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome, Leader!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
