import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  static const _langs = <Map<String, String>>[
    {'code': 'en', 'name': 'English'},
    {'code': 'bn', 'name': 'Bangla'},
    {'code': 'tr', 'name': 'Turkish'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'it', 'name': 'Italy'},
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Please login")));
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final code = (snap.data?.data()?['language'] ?? 'en').toString();
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Language"),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _langs.length,
            itemBuilder: (context, i) {
              final lang = _langs[i];
              final isSel = lang['code'] == code;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: ListTile(
                  title: Text(lang['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: isSel ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => ref.set({'language': lang['code']}, SetOptions(merge: true)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

