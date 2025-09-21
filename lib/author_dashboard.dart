import 'package:cp_final/create_post_page.dart';
import 'package:cp_final/login.dart';
import 'package:cp_final/my_content_page.dart';
import 'package:cp_final/profile_page.dart';
import 'package:cp_final/service/auth.dart';
import 'package:flutter/material.dart';

class AuthorDashboard extends StatefulWidget {
  const AuthorDashboard({Key? key}) : super(key: key);

  @override
  State<AuthorDashboard> createState() => _AuthorDashboardState();
}

class _AuthorDashboardState extends State<AuthorDashboard> {
  int _selectedIndex = 0;

  // --- FIX: REMOVED 'const' FROM THIS LIST DEFINITION ---
  // This allows the list to hold stateful widgets like ProfilePage
  static final List<Widget> _pages = <Widget>[
    const DashboardHomePage(),
    const MyContentPage(),
    const CreatePostPage(), // This is a placeholder, not shown directly
    const InboxPage(),
    const ProfilePage(), // Now this is valid
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const CreatePostPage()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _pages.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'My Content',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 40),
            label: 'Create',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Inbox'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF59AC77),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// --- PLACEHOLDER PAGES ---
// These are simple and can be 'const'
class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF59AC77),
      ),
      body: const Center(
        child: Text('Dashboard (Home) Page - Stats will go here.'),
      ),
    );
  }
}

class InboxPage extends StatelessWidget {
  const InboxPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: const Color(0xFF59AC77),
      ),
      body: const Center(
        child: Text('Inbox Page - Reviews and comments will go here.'),
      ),
    );
  }
}
