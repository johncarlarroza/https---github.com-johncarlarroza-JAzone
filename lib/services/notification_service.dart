import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  NotificationService._();
  factory NotificationService() => _instance;

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Ask permission (iOS / Android 13+)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Optional: get token for admin backend to target this device
    // final token = await messaging.getToken();

    // Foreground handler can be added later
  }
}
