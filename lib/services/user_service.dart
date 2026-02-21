import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data() ?? {});
  }

  Future<void> createCitizenProfile({
    required String uid,
    required String fullName,
    String? phone,
    String? email,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'role': 'citizen',
      'fullName': fullName.isEmpty ? 'Citizen' : fullName,
      'phone': phone,
      'email': email,
      'photoUrl': null,
      'isOnline': true,
      'lastLoginAt': now,
      'lastLogoutAt': null,
      'createdAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> createResponderProfile({
    required String uid,
    required String fullName,
    String? phone,
    String? email,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'role': 'responder',
      'fullName': fullName.isEmpty ? 'Responder' : fullName,
      'phone': phone,
      'email': email,
      'photoUrl': null,
      'isOnline': true,
      'lastLoginAt': now,
      'lastLogoutAt': null,
      'createdAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> ensureCitizenProfile(
    String uid, {
    String? phone,
    String? email,
  }) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      await createCitizenProfile(
        uid: uid,
        fullName: 'Citizen',
        phone: phone,
        email: email,
      );
      return;
    }

    // If exists but role mismatch, we do NOT auto-change role (strict)
    final role = (doc.data()?['role'] ?? '').toString();
    if (role.isNotEmpty && role != 'citizen') {
      throw Exception('This account is not a Citizen account.');
    }

    await _db.collection('users').doc(uid).set({
      'isOnline': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    }, SetOptions(merge: true));
  }

  Future<void> ensureResponderProfile(
    String uid, {
    String? phone,
    String? email,
  }) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      await createResponderProfile(
        uid: uid,
        fullName: 'Responder',
        phone: phone,
        email: email,
      );
      return;
    }

    final role = (doc.data()?['role'] ?? '').toString();
    if (role.isNotEmpty && role != 'responder') {
      throw Exception('This account is not a Responder account.');
    }

    await _db.collection('users').doc(uid).set({
      'isOnline': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    }, SetOptions(merge: true));
  }

  Future<void> setLoggedOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'isOnline': false,
      'lastLogoutAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
