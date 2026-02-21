import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'auth/auth_gate.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart'; // ✅ make sure this path matches your project

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // dotenv is optional; don't crash if missing
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // Firebase init
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAZaVdmD0LFtLhUIwWY9bDDtAk9oHpJs8c",
        appId: "1:138870655176:android:2d1e949e28917c3e50bdfd",
        messagingSenderId: "138870655176",
        projectId: "jazone-58ee0",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // App Check (debug for development)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // ✅ Supabase (Storage only) - do not remove
  await Supabase.initialize(
    url: 'https://rexxegloqouxluevnftp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJleHhlZ2xvcW91eGx1ZXZuZnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzMjkzNDIsImV4cCI6MjA4MTkwNTM0Mn0.jcbUMMl-m3AZNVhMVHoPhUXgDnDfN1D_BPD6Toyg_es',
  );

  await NotificationService().init();

  runApp(const JAzoneApp());
}

class JAzoneApp extends StatelessWidget {
  const JAzoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Providers MUST be above MaterialApp so ALL routes can access them
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        // Add more providers here later (UserService, ReportService, etc.)
      ],
      child: MaterialApp(
        title: 'JAzone',
        debugShowCheckedModeBanner: false,

        // ✅ Keep your theme init, but replace this with your Theme Utils theme
        theme: ThemeData(useMaterial3: true),

        home: const AuthGate(),
      ),
    );
  }
}
