import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('About JAzone'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Text(
            'JAzone is a community safety and incident reporting app trusted by Janiuay, Iloilo City and DRRMO.\n\n'
            'It provides real-time monitoring of citizen reports, supports responder dispatch, and keeps citizens updated on report progress.',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15, height: 1.4),
          ),
        ),
      ),
    );
  }
}
