import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ParentChildAccountsPage extends StatefulWidget {
  const ParentChildAccountsPage({super.key});

  @override
  State<ParentChildAccountsPage> createState() => _ParentChildAccountsPageState();
}

class _ParentChildAccountsPageState extends State<ParentChildAccountsPage> {
  final name = TextEditingController();
  final username = TextEditingController();
  final pin = TextEditingController();
  final dailyLimit = TextEditingController(text: '0');
  final cardLimit = TextEditingController(text: '0');
  bool saving = false;

  Future<void> createChild() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || name.text.trim().isEmpty || username.text.trim().isEmpty || pin.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('children').add({
        'parentUserId': uid,
        'name': name.text.trim(),
        'username': username.text.trim().toLowerCase(),
        'pin': pin.text.trim(),
        'balance': 0,
        'dailyLimit': num.tryParse(dailyLimit.text.trim()) ?? 0,
        'cardLimit': num.tryParse(cardLimit.text.trim()) ?? 0,
        'transferLimit': num.tryParse(dailyLimit.text.trim()) ?? 0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      name.clear();
      username.clear();
      pin.clear();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Child Accounts"), backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
      body: uid == null
          ? const Center(child: Text("Please login"))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section("Create child account"),
                _field("Child name", name),
                _field("Child username", username),
                _field("PIN", pin, obscure: true),
                _field("Daily limit", dailyLimit, number: true),
                _field("Card limit", cardLimit, number: true),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saving ? null : createChild,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A6E79), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(saving ? "Creating..." : "Create", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                _section("My child accounts"),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('children').where('parentUserId', isEqualTo: uid).snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No child accounts yet"));
                    return Column(
                      children: docs.map((d) {
                        final c = d.data();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Limit ₦${c['dailyLimit'] ?? 0} · Balance ₦${c['balance'] ?? 0}"),
                            trailing: Switch(
                              value: c['status'] == 'active',
                              onChanged: (v) => FirebaseFirestore.instance.collection('children').doc(d.id).set({'status': v ? 'active' : 'paused'}, SetOptions(merge: true)),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                )
              ],
            ),
    );
  }

  Widget _section(String text) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
  Widget _field(String hint, TextEditingController c, {bool obscure = false, bool number = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: TextField(controller: c, obscureText: obscure, keyboardType: number ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.all(16))),
    );
  }
}

