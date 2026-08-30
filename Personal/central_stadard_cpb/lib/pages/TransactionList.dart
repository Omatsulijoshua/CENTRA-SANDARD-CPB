import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Please login"));

    final q = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No transactions yet"));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final tx = docs[index].data();
            final direction = (tx['direction'] ?? '').toString(); // "debit" | "credit"
            final isDebit = direction == 'debit';
            final amount = tx['amount'];
            final createdAt = tx['createdAt'];
            final when = createdAt is Timestamp ? createdAt.toDate() : null;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: Icon(
                  isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isDebit ? Colors.red : Colors.green,
                ),
                title: Text(
                  isDebit ? "Sent to ${tx['counterpartyAccount'] ?? ''}" : "Received Funds",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Amount: ₦${(amount is num ? amount : 0).toStringAsFixed(2)}"),
                trailing: Text(
                  when != null ? when.toString().split('.').first : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

