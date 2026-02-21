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

  static const List<Widget> _pages = [
    HomePageScreen(),
    MyReportsPage(), // ✅ keep this as the tab
    AlertsPage(),
    AboutUsPage(),
    SettingsPage(),
  ];

  void _onNavTap(int index) {
    final safe = index.clamp(0, _pages.length - 1);
    if (!mounted) return;
    setState(() => _currentIndex = safe);
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _currentIndex.clamp(0, _pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1F3A),
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.white.withOpacity(0.65),
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'My Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About Us'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
