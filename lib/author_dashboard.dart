import 'package:cp_final/create_post_page.dart';
import 'package:cp_final/login.dart';
import 'package:cp_final/service/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthorDashboard extends StatelessWidget {
  const AuthorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Author Dashboard'),
        backgroundColor: const Color(0xFF59AC77), // Match your theme color
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, Author!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'Your posts will appear here.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            const Text(
              'You have no posts yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the Create Post page
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          );
        },
        backgroundColor: const Color(0xFF59AC77),
        tooltip: 'Create New Post',
        child: const Icon(Icons.add),
      ),
    );
  }
}
