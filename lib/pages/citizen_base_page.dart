import 'package:flutter/material.dart';

import 'aboutus.dart';
import 'alerts.dart';
import 'homepage.dart';
import 'reports.dart';
import 'settings.dart';

class CitizenBasePage extends StatefulWidget {
  const CitizenBasePage({super.key});

  @override
  State<CitizenBasePage> createState() => _CitizenBasePageState();
}

class _CitizenBasePageState extends State<CitizenBasePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePageScreen(),
    MyReportsPage(),
    AlertsPage(),
    AboutUsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final safeIndex = (_currentIndex >= 0 && _currentIndex < _pages.length) ? _currentIndex : 0;

    return Scaffold(
      body: _pages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1F3A),
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.white.withOpacity(0.65),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'My Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About Us'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
