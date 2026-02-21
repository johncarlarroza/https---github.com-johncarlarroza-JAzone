import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pages/citizen_base_page.dart';
import '../responder/responder_base_page.dart';
import 'role_selection_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _ensureUserProfile(User user) async {
    final usersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snap = await usersRef.get();

    // ✅ If profile missing, create a safe default profile (Citizen)
    if (!snap.exists) {
      await usersRef.set({
        'uid': user.uid,
        'role': 'citizen', // ✅ safe default
        'email': user.email,
        'phone': user.phoneNumber,
        'name': '',
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    // ✅ If profile exists, update online/login timestamps
    await usersRef.set({
      'isOnline': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

        // Not logged in -> pick role (citizen/responder)
        if (user == null) {
          return const RoleSelectionPage();
        }

        // Logged in -> make sure profile exists then route by role
        return FutureBuilder<void>(
          future: _ensureUserProfile(user),
          builder: (context, fixSnap) {
            if (fixSnap.connectionState == ConnectionState.waiting) {
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
                  // Should not happen because we ensure profile above
                  return const RoleSelectionPage();
                }

                final data = profileSnap.data!.data() ?? <String, dynamic>{};
                final role = (data['role'] ?? '').toString().toLowerCase();

                if (role == 'citizen') return const CitizenBasePage();
                if (role == 'responder') return const ResponderBasePage();

                // Unknown role -> go back to role selection
                return const RoleSelectionPage();
              },
            );
          },
        );
      },
    );
  }
}
