import 'package:flutter/material.dart';
import 'dart:async';
import 'login.dart'; // import your login page
import 'main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:central_stadard_cpb/services/push_notification_service.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  @override
  void initState() {
    super.initState();

    // Wait 5 seconds then go to Login page
    Timer(const Duration(seconds: 5), () {
      final authed = FirebaseAuth.instance.currentUser != null;
      // Fire-and-forget: request push permission and store FCM token (if logged in).
      PushNotificationService().init();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => authed ? const MainPage() : const Login()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // PURE WHITE BACKGROUND
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 140),
              child: Image.asset('assets/logo.png', width: 300, height: 300),
            ),
            const SizedBox(height: 20),
            const Text(
              "Central Standard CPB",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "bank simply with smile",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
