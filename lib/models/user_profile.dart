// TODO Implement this library.
class UserProfile {
  final String uid;
  final String role; // 'citizen' | 'responder'
  final String fullName;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final bool isOnline;

  UserProfile({
    required this.uid,
    required this.role,
    required this.fullName,
    this.phone,
    this.email,
    this.photoUrl,
    required this.isOnline,
  });

  /// Convert Firestore map → Model
  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      role: (data['role'] ?? '').toString(),
      fullName: (data['fullName'] ?? '').toString(),
      phone: data['phone']?.toString(),
      email: data['email']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      isOnline: (data['isOnline'] == true),
    );
  }

  /// Convert Model → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
    };
  }
}
