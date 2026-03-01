import 'package:flutter/material.dart';
import '../widgets/auth_scaffold.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset('assets/logo.png', height: 120),
          const SizedBox(height: 20),
          const Text(
            'JAzone',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Emergency Response & Citizen Reporting System',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 40),

          _roleButton(
            context,
            label: "Continue as Citizen",
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _roleButton(
            context,
            label: "Continue as Responder",
            icon: Icons.local_police,
          ),
        ],
      ),
    );
  }

  Widget _roleButton(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
      ),
    );
  }
}
