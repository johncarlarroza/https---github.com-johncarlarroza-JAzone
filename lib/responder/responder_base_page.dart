import 'package:flutter/material.dart';

import 'responder_home_page.dart';
import 'responder_history_page.dart';
import 'responder_profile_page.dart';

class ResponderBasePage extends StatefulWidget {
  const ResponderBasePage({super.key});

  @override
  State<ResponderBasePage> createState() => _ResponderBasePageState();
}

class _ResponderBasePageState extends State<ResponderBasePage> {
  int _currentIndex = 0;

  final _pages = const [
    ResponderHomePage(),
    ResponderHistoryPage(),
    ResponderProfilePage(),
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
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
