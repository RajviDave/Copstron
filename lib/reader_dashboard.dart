import 'package:cp_final/reader/home_reader.dart';
import 'package:cp_final/reader/explore_page.dart';
import 'package:cp_final/reader/library_reader.dart';
import 'package:cp_final/reader/events_reader_clean.dart';
import 'package:cp_final/reader/profile_reader.dart';
import 'package:cp_final/service/auth.dart';
import 'package:flutter/material.dart';

class ReaderDashboard extends StatefulWidget {
  const ReaderDashboard({super.key});

  @override
  State<ReaderDashboard> createState() => _ReaderDashboardState();
}

class _ReaderDashboardState extends State<ReaderDashboard> {
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();

  static final List<Widget> _pages = <Widget>[
    const HomeReader(),
    const ExplorePage(),
    const LibraryReader(),
    const EventsReader(),
    const ProfileReader(), // This is now the correct ProfileReader from reader/profile_reader.dart
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _pages.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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

// Imported pages from their respective files
