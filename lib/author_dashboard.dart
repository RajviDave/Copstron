import 'package:cp_final/create_post_page.dart';
import 'package:cp_final/login.dart';
import 'package:cp_final/service/auth.dart';
import 'package:flutter/material.dart';

// This is the main stateful widget that will manage the navigation
class AuthorDashboard extends StatefulWidget {
  const AuthorDashboard({Key? key}) : super(key: key);

  @override
  State<AuthorDashboard> createState() => _AuthorDashboardState();
}

class _AuthorDashboardState extends State<AuthorDashboard> {
  // This controller will keep track of the currently selected tab
  int _selectedIndex = 0;

  // This is the list of pages that correspond to each tab
  static const List<Widget> _pages = <Widget>[
    DashboardHomePage(), // The "Home" screen with stats
    MyContentPage(), // The "My Content" screen
    CreatePostPage(), // The "Create" screen (using our existing page)
    InboxPage(), // The "Inbox" screen
    ProfilePage(), // The "Profile" screen
  ];

  // This function is called when a user taps on a navigation bar item
  void _onItemTapped(int index) {
    // If the user taps the "Create" button (index 2), we handle it differently
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CreatePostPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body of the scaffold will be the currently selected page
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      // This is the bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        // These are the buttons that will appear on the bar
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
            icon: Icon(Icons.add_circle, size: 40), // A larger, central button
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF59AC77), // Your primary color
        unselectedItemColor: Colors.grey, // Make unselected items grey
        showUnselectedLabels: true, // Show labels for all items
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
      ),
    );
  }
}

// --- PLACEHOLDER PAGES ---
// We will build these out in the next steps. For now, they are just simple pages.

class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), backgroundColor: const Color(0xFF59AC77)),
      body: const Center(child: Text('Dashboard (Home) Page - Stats will go here.')),
    );
  }
}

class MyContentPage extends StatelessWidget {
  const MyContentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Content'), backgroundColor: const Color(0xFF59AC77)),
      body: const Center(child: Text('My Content Page - List of books will go here.')),
    );
  }
}

class InboxPage extends StatelessWidget {
  const InboxPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox'), backgroundColor: const Color(0xFF59AC77)),
      body: const Center(child: Text('Inbox Page - Reviews and comments will go here.')),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF59AC77),
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
      body: const Center(child: Text('Profile Page - User settings will go here.')),
    );
  }
}

