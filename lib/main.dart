import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:jazone_1/base_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jazone_1/screens/splast_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

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

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  await Supabase.initialize(
    url: 'https://rexxegloqouxluevnftp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJleHhlZ2xvcW91eGx1ZXZuZnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzMjkzNDIsImV4cCI6MjA4MTkwNTM0Mn0.jcbUMMl-m3AZNVhMVHoPhUXgDnDfN1D_BPD6Toyg_es',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JAzone',
      routes: {
        '/': (context) => const SplashScreen(child: BasePage()),
        '/home': (context) => const BasePage(),
      },
    );
  }
}
