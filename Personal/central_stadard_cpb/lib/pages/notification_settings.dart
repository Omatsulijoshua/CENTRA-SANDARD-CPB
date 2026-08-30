import 'package:central_stadard_cpb/services/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Please login")));

    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final settings = (data['notificationSettings'] as Map?)?.cast<String, dynamic>() ?? {};

        bool v(String k) => (settings[k] ?? false) == true;

        Future<void> setFlag(String k, bool val) async {
          await ref.set({
            'notificationSettings': {k: val}
          }, SetOptions(merge: true));
          if (k == 'push' && val) {
            await PushNotificationService().init();
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Notification Settings"),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _toggle(
                  title: "Notification Settings",
                  subtitle: "Receive in-app push to find out what's going on when you're offline",
                  value: v('push'),
                  onChanged: (val) => setFlag('push', val),
                ),
                _toggle(
                  title: "Email Notifications",
                  subtitle: "Get emails to find out about transactions and notifications",
                  value: v('email'),
                  onChanged: (val) => setFlag('email', val),
                ),
                _toggle(
                  title: "Sms Notifications",
                  subtitle: "Get sms to find out about transactions and notifications",
                  value: v('sms'),
                  onChanged: (val) => setFlag('sms', val),
                ),
                _toggle(
                  title: "Promotional Offer",
                  subtitle: "Get push notifications about promotional offers",
                  value: v('promo'),
                  onChanged: (val) => setFlag('promo', val),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

