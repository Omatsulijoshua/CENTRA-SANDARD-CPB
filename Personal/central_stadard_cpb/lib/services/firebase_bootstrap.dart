import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    if (kIsWeb) {
      // For web, firebase_options.dart is recommended via `flutterfire configure`.
      // This project currently relies on native config files for Android/iOS.
      await Firebase.initializeApp();
      return;
    }
    await Firebase.initializeApp();
  }
}

