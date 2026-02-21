import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ✅ SIGN UP
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    bool forceFixProfile = true, // ✅ NOW DEFINED
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (forceFixProfile) {
      await _createOrFixUserProfile(
        uid: cred.user!.uid,
        email: email,
        role: "citizen",
      );
    }

    return cred;
  }

  // ✅ SIGN IN
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
    bool forceFixProfile = true, // also allowed here
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (forceFixProfile) {
      await _createOrFixUserProfile(uid: cred.user!.uid, email: email);
    }

    return cred;
  }

  // ✅ PROFILE CREATOR / FIXER
  Future<void> _createOrFixUserProfile({
    required String uid,
    required String email,
    String role = "citizen",
  }) async {
    final ref = _firestore.collection('users').doc(uid);

    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'uid': uid,
        'email': email,
        'role': role,
        'isOnline': true,
        'locationEnabled': false,
        'availabilityStatus': role == "responder" ? "unavailable" : null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'isOnline': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ✅ LOGOUT
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;

    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'lastLogoutAt': FieldValue.serverTimestamp(),
      });
    }

    await _auth.signOut();
  }
}
