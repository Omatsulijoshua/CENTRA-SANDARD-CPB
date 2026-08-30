import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupportTicketPage extends StatelessWidget {
  const SupportTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Please login")));

    final q = FirebaseFirestore.instance
        .collection('supportTickets')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Support Ticket"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSupportTicketPage())),
        backgroundColor: const Color(0xFF0A6E79),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Create", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.support_agent, size: 54, color: Colors.black38),
                  SizedBox(height: 10),
                  Text("Sorry! there are no tickets to show", style: TextStyle(color: Colors.black54)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final t = docs[i].data();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: ListTile(
                  title: Text((t['subject'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text((t['message'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text((t['status'] ?? 'open').toString(), style: const TextStyle(color: Colors.black54)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CreateSupportTicketPage extends StatefulWidget {
  const CreateSupportTicketPage({super.key});

  @override
  State<CreateSupportTicketPage> createState() => _CreateSupportTicketPageState();
}

class _CreateSupportTicketPageState extends State<CreateSupportTicketPage> {
  final subject = TextEditingController();
  final message = TextEditingController();
  String priority = 'Low';
  bool saving = false;

  @override
  void dispose() {
    subject.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (subject.text.trim().isEmpty || message.text.trim().isEmpty) return;

    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('supportTickets').add({
        'userId': uid,
        'subject': subject.text.trim(),
        'priority': priority,
        'message': message.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
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
        title: const Text("Create Support Ticket"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field("Subject", subject),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
              child: DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                ],
                onChanged: (v) => setState(() => priority = v ?? 'Low'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
              child: TextField(
                controller: message,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "Enter your message",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: saving ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A6E79),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController c) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

