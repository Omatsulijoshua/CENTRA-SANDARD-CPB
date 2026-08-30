import 'package:central_stadard_cpb/pages/login.dart';
import 'package:central_stadard_cpb/pages/personal_information.dart';
import 'package:central_stadard_cpb/pages/notification_settings.dart';
import 'package:central_stadard_cpb/pages/support_ticket.dart';
import 'package:central_stadard_cpb/pages/app_preference.dart';
import 'package:central_stadard_cpb/pages/biometric_settings.dart';
import 'package:central_stadard_cpb/pages/parent_child_accounts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final name = (data['name'] ?? 'User').toString();
        final phone = (data['phone'] ?? '').toString();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: const Color(0xFF0A6E79),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0A6E79), Color(0xFF054C53)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const CircleAvatar(radius: 44, backgroundImage: AssetImage('assets/profile.jpg')),
                        const SizedBox(height: 14),
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 18),
                  _buildTile(context, Icons.person_outline, "Personal information", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInformationPage()));
                  }),
                  _buildTile(context, Icons.notifications_none, "Notification", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsPage()));
                  }),
                  _buildTile(context, Icons.lock_outline, "Security", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BiometricSettingsPage()));
                  }),
                  _buildTile(context, Icons.child_care, "Child Accounts", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentChildAccountsPage()));
                  }),
                  _buildTile(context, Icons.support_agent, "Support Ticket", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketPage()));
                  }),
                  _buildTile(context, Icons.privacy_tip_outlined, "Privacy Settings", onTap: () {}),
                  _buildTile(context, Icons.settings, "App Preference", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AppPreferencePage()));
                  }),
                  const SizedBox(height: 12),
                  _buildTile(
                    context,
                    Icons.logout,
                    "Logout",
                    color: Colors.red,
                    showArrow: false,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title, {
    Color color = Colors.black87,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: showArrow ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      ),
    );
  }
}
