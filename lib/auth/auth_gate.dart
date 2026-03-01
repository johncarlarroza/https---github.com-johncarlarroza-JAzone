import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pages/citizen_base_page.dart';
import '../responder/responder_base_page.dart';
import 'role_selection_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _touchLogin(User user) async {
    // Only touch online/login timestamps (DO NOT create default role)
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'phone': user.phoneNumber,
      'isOnline': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _signOutSilently() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;

        if (user == null) {
          return const RoleSelectionPage();
        }

        return FutureBuilder<void>(
          future: _touchLogin(user),
          builder: (context, touchSnap) {
            if (touchSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, profileSnap) {
                if (profileSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!profileSnap.hasData || !profileSnap.data!.exists) {
                  // No profile -> force re-auth
                  _signOutSilently();
                  return const RoleSelectionPage();
                }

                final data = profileSnap.data!.data() ?? <String, dynamic>{};
                final role = (data['role'] ?? '')
                    .toString()
                    .toLowerCase()
                    .trim();

                if (role == 'citizen') return const CitizenBasePage();
                if (role == 'responder') return const ResponderBasePage();

                // Unknown/empty role
                _signOutSilently();
                return const RoleSelectionPage();
              },
            );
          },
        );
      },
    );
  }
}
