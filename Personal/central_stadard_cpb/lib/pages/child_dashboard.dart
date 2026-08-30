import 'package:flutter/material.dart';

class ChildDashboard extends StatelessWidget {
  final Map<String, dynamic> childData;
  const ChildDashboard({super.key, required this.childData});

  @override
  Widget build(BuildContext context) {
    final data = childData;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Child Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF0A6E79), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? 'Child', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text("Balance", style: TextStyle(color: Colors.white70)),
                Text("₦${NumberFormatLite.money(data['balance'])}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _tile("Daily limit", "₦${NumberFormatLite.money(data['dailyLimit'])}"),
          _tile("Card limit", "₦${NumberFormatLite.money(data['cardLimit'])}"),
          _tile("Transfer limit", "₦${NumberFormatLite.money(data['transferLimit'])}"),
          const SizedBox(height: 18),
          const Text("Cards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _tile("Virtual card", "Available when parent enables it"),
          _tile("Physical card", "Order status appears here"),
        ],
      ),
    );
  }

  Widget _tile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle)),
    );
  }
}

class NumberFormatLite {
  static String money(dynamic value) {
    final n = value is num ? value : 0;
    return n.toStringAsFixed(2);
  }
}
