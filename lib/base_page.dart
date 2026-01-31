import 'package:flutter/material.dart';
import 'package:jazone_1/pages/aboutus.dart';
import 'package:jazone_1/pages/alerts.dart';
import 'package:jazone_1/pages/homepage.dart';
import 'package:jazone_1/pages/reports.dart';
import 'package:jazone_1/pages/settings.dart';

class BasePage extends StatefulWidget {
  const BasePage({Key? key}) : super(key: key);

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePageScreen(),
    const MyReportsPage(),
    const AlertsPage(),
    const AboutUsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1F3A),
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.grey.shade600,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
