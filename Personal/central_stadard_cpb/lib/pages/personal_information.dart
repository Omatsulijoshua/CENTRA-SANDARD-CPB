import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PersonalInformationPage extends StatelessWidget {
  const PersonalInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Please login")));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Personal information"),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 26, backgroundImage: AssetImage('assets/profile.jpg')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((data['name'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text((data['phone'] ?? '—').toString(), style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Edit", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _infoTile("Email", (data['email'] ?? '—').toString()),
                _infoTile("Country", (data['country'] ?? '—').toString()),
                _infoTile("Account Number", (data['accountNumber'] ?? '—').toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final zip = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    city.dispose();
    state.dispose();
    zip.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data() ?? {};
    name.text = (data['name'] ?? '').toString();
    phone.text = (data['phone'] ?? '').toString();
    address.text = (data['address'] ?? '').toString();
    city.text = (data['city'] ?? '').toString();
    state.text = (data['state'] ?? '').toString();
    zip.text = (data['zip'] ?? '').toString();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
        'city': city.text.trim(),
        'state': state.text.trim(),
        'zip': zip.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? "Saving…" : "Save", style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field("Full Name", name),
            _field("Phone Number", phone),
            _field("Address", address),
            _field("State", state),
            _field("Zip Code", zip),
            _field("City", city),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

