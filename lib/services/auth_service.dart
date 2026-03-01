import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { citizen, responder }

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // PHONE NORMALIZATION (PH)
  // Canonical: 09xxxxxxxxx
  // =========================
  String normalizePhone(String phone) {
    var p = phone.trim();
    // remove spaces + dashes
    p = p.replaceAll(RegExp(r'[\s\-]'), '');

    // +63XXXXXXXXXX -> 0XXXXXXXXXX
    if (p.startsWith('+63')) p = '0${p.substring(3)}';

    // 63XXXXXXXXXX -> 0XXXXXXXXXX
    if (p.startsWith('63')) p = '0${p.substring(2)}';

    // 9XXXXXXXXX -> 09XXXXXXXXX
    if (p.length == 10 && p.startsWith('9')) p = '0$p';

    return p;
  }

  // Phone -> synthetic email
  // IMPORTANT: always pass a NORMALIZED phone to this
  String _phoneToEmailFromNormalized(String normalizedPhone) {
    return '$normalizedPhone@jazone.local';
  }

  // Used for accounts created with old formats
  List<String> _candidateEmailsFromInputPhone(String phone) {
    final raw = phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
    final normalized = normalizePhone(raw);

    final noPlus = raw.replaceAll('+', '');

    // Some users may have registered with:
    // - 09xxxxxxxxx@jazone.local
    // - 639xxxxxxxxx@jazone.local
    // - 9xxxxxxxxx@jazone.local
    final candidates = <String>{
      _phoneToEmailFromNormalized(normalized),
      '$noPlus@jazone.local',
      '${noPlus.replaceFirst('63', '0')}@jazone.local',
      '${normalized.startsWith('0') ? normalized.substring(1) : normalized}@jazone.local', // 9xxxxxxxxx@...
      '${normalized.startsWith('0') ? '63${normalized.substring(1)}' : normalized}@jazone.local', // 63...
    };

    return candidates.toList();
  }

  Future<void> _saveUserProfile({
    required String uid,
    required String name,
    required UserRole role,
    String? phone,
    String? email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name.trim(),
      'role': role.name, // citizen | responder
      'phone': phone,
      'email': email,
      'isOnline': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> _getRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    final role = (data['role'] ?? '').toString().toLowerCase().trim();
    return role.isEmpty ? null : role;
  }

  // Optional safety: block duplicate phone signup
  Future<void> _ensurePhoneNotUsed(String normalizedPhone) async {
    final snap = await _firestore
        .collection('users')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      throw Exception('Phone number already registered. Please login instead.');
    }
  }

  /// ==============================
  /// SIGN UP — PHONE + PASSWORD (phone->email trick)
  /// ==============================
  Future<User> signUpWithPhonePassword({
    required String phone,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final normalizedPhone = normalizePhone(phone);

    if (normalizedPhone.isEmpty ||
        !normalizedPhone.startsWith('09') ||
        normalizedPhone.length != 11) {
      throw Exception(
        'Invalid phone number. Use format 09xxxxxxxxx or +63xxxxxxxxxx.',
      );
    }
    if (password.trim().length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    if (name.trim().isEmpty) {
      throw Exception('Name is required.');
    }

    // prevents multiple accounts using same phone
    await _ensurePhoneNotUsed(normalizedPhone);

    final syntheticEmail = _phoneToEmailFromNormalized(normalizedPhone);

    final cred = await _auth.createUserWithEmailAndPassword(
      email: syntheticEmail,
      password: password.trim(),
    );

    final user = cred.user;
    if (user == null) throw Exception("Signup failed.");

    await _saveUserProfile(
      uid: user.uid,
      name: name,
      role: role,
      phone: normalizedPhone,
      email: null,
    );

    return user;
  }

  /// ==============================
  /// SIGN UP — EMAIL + PASSWORD
  /// ==============================
  Future<User> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    if (password.trim().length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    if (name.trim().isEmpty) {
      throw Exception('Name is required.');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = cred.user;
    if (user == null) throw Exception("Signup failed.");

    await _saveUserProfile(
      uid: user.uid,
      name: name,
      role: role,
      phone: null,
      email: email.trim(),
    );

    return user;
  }

  /// ==============================
  /// LOGIN — PHONE + PASSWORD
  /// Tries multiple candidate emails to support old accounts
  /// ==============================
  Future<User> signInWithPhonePassword({
    required String phone,
    required String password,
    required UserRole selectedRole,
  }) async {
    final candidates = _candidateEmailsFromInputPhone(phone);

    UserCredential? cred;
    FirebaseAuthException? lastAuthErr;

    for (final email in candidates) {
      try {
        cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password.trim(),
        );
        break;
      } on FirebaseAuthException catch (e) {
        lastAuthErr = e;
      }
    }

    final user = cred?.user;
    if (user == null) {
      throw Exception(lastAuthErr?.message ?? 'Invalid phone or password.');
    }

    final existingRole = await _getRole(user.uid);
    if (existingRole != null && existingRole != selectedRole.name) {
      await _auth.signOut();
      throw Exception(
        "This account is registered as ${existingRole.toUpperCase()}, not ${selectedRole.name.toUpperCase()}.",
      );
    }

    // Touch login status + ensure canonical phone is stored
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'isOnline': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'phone': normalizePhone(phone),
    }, SetOptions(merge: true));

    return user;
  }

  /// ==============================
  /// LOGIN — EMAIL + PASSWORD
  /// ==============================
  Future<User> signInWithEmailPassword({
    required String email,
    required String password,
    required UserRole selectedRole,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = cred.user;
    if (user == null) throw Exception("Login failed.");

    final existingRole = await _getRole(user.uid);
    if (existingRole != null && existingRole != selectedRole.name) {
      await _auth.signOut();
      throw Exception(
        "This account is registered as ${existingRole.toUpperCase()}, not ${selectedRole.name.toUpperCase()}.",
      );
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'isOnline': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'email': email.trim(),
    }, SetOptions(merge: true));

    return user;
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).set({
        'isOnline': false,
        'lastLogoutAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await _auth.signOut();
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
