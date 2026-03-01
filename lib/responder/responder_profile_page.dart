import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jazone_1/auth/login_page.dart';

import '../auth/role_selection_page.dart';
import '../services/location_tracking_service.dart';

class ResponderProfilePage extends StatelessWidget {
  const ResponderProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // stop tracking if running
      await LocationTrackingService().stopTracking();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isOnline': false,
        'lastLogoutAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseAuth.instance.signOut();
    }
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('Profile'),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please login',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() ?? {};
                final name = (data['fullName'] ?? '').toString();
                final phone = (data['phone'] ?? '').toString();
                final email = (data['email'] ?? user.email ?? '').toString();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F3A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Responder' : name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _row('Phone', phone.isEmpty ? '-' : phone),
                          _row('Email', email.isEmpty ? '-' : email),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Log out'),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              k,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
