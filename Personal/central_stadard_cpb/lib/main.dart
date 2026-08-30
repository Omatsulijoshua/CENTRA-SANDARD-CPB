import 'package:central_stadard_cpb/pages/launch.dart';
import 'package:central_stadard_cpb/services/firebase_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.ensureInitialized();

  runApp(
    // Enable DevicePreview only in debug mode
    kDebugMode
        ? DevicePreview(builder: (context) => const MyApp())
        : const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Only use DevicePreview settings if it's enabled
      locale: kDebugMode ? DevicePreview.locale(context) : null,
      builder: kDebugMode ? DevicePreview.appBuilder : null,
      useInheritedMediaQuery: kDebugMode,
      debugShowCheckedModeBanner: false,
      title: 'Central Standard CPB',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      home: const LaunchPage(),
    );
  }
}
