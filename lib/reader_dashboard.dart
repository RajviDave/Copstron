import 'package:cp_final/login.dart';
import 'package:cp_final/reader/home_reader.dart';
import 'package:cp_final/reader/explore_reader.dart';
import 'package:cp_final/reader/library_reader.dart';
import 'package:cp_final/reader/events_reader.dart';
import 'package:cp_final/reader/profile_reader.dart';
import 'package:cp_final/service/auth.dart';
import 'package:flutter/material.dart';

class ReaderDashboard extends StatefulWidget {
  const ReaderDashboard({Key? key}) : super(key: key);

  @override
  State<ReaderDashboard> createState() => _ReaderDashboardState();
}

class _ReaderDashboardState extends State<ReaderDashboard> {
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();

  static final List<Widget> _pages = <Widget>[
    const HomeReader(),
    const ExploreReader(),
    const LibraryReader(),
    const EventsReader(),
    const ProfileReader(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF59AC77), // Match the primary color
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}

// Placeholder pages - these will be implemented in separate files
class HomeReader extends StatelessWidget {
  const HomeReader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home - Your personalized feed'));
  }
}

class ExploreReader extends StatelessWidget {
  const ExploreReader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Explore - Discover new books and authors'));
  }
}

class LibraryReader extends StatelessWidget {
  const LibraryReader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Library - Your saved books and lists'));
  }
}

class EventsReader extends StatelessWidget {
  const EventsReader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Events - Upcoming book events and talks'));
  }
}

class ProfileReader extends StatelessWidget {
  const ProfileReader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile - Your account and settings'));
  }
}
