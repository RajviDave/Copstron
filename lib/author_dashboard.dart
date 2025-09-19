import 'package:cp_final/login.dart';
import 'package:cp_final/service/auth.dart';
import 'package:flutter/material.dart';

class AuthorDashboard extends StatelessWidget {
  const AuthorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Author Dashboard'),
        backgroundColor: const Color(0xFF59AC77),
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
          'Welcome, Author!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
