import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricSettingsPage extends StatefulWidget {
  const BiometricSettingsPage({super.key});

  @override
  State<BiometricSettingsPage> createState() => _BiometricSettingsPageState();
}

class _BiometricSettingsPageState extends State<BiometricSettingsPage> {
  final LocalAuthentication auth = LocalAuthentication();
  List<BiometricType> biometrics = [];
  bool canCheck = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final can = await auth.canCheckBiometrics;
    final available = await auth.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        canCheck = can;
        biometrics = available;
      });
    }
  }

  Future<void> _setPreference(String mode, bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'biometricPreference': enabled ? mode : 'off',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Please login")));
    final supportsFace = biometrics.contains(BiometricType.face);
    final supportsFingerprint = biometrics.contains(BiometricType.fingerprint) || biometrics.contains(BiometricType.strong);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final selected = (snap.data?.data()?['biometricPreference'] ?? 'off').toString();
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(title: const Text("Security"), backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Biometric sign in", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(canCheck ? "Choose any biometric method supported by this device." : "This device does not report biometric support.", style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                _option("Off", "Use password or child PIN only", selected == 'off', () => _setPreference('off', false)),
                if (supportsFace) _option("Face ID", "Use face authentication", selected == 'face', () => _setPreference('face', true)),
                if (supportsFingerprint) _option("Fingerprint", "Use fingerprint authentication", selected == 'fingerprint', () => _setPreference('fingerprint', true)),
                if (supportsFace && supportsFingerprint) _option("Device default", "Let the device pick the best available method", selected == 'device', () => _setPreference('device', true)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _option(String title, String subtitle, bool selected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE7F6F7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? const Color(0xFF0A6E79) : Colors.black.withOpacity(0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check_circle, color: Color(0xFF0A6E79)) : const Icon(Icons.circle_outlined),
      ),
    );
  }
}

