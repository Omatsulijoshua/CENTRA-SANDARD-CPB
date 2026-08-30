import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'card_payment_page.dart';

class MyCard extends StatefulWidget {
  const MyCard({super.key});

  @override
  State<MyCard> createState() => _MyCardState();
}

class _MyCardState extends State<MyCard> {
  final bankNameController = TextEditingController();
  final holderNameController = TextEditingController();
  final last4Controller = TextEditingController();
  final expiryController = TextEditingController();
  String network = 'Visa';

  @override
  void dispose() {
    bankNameController.dispose();
    holderNameController.dispose();
    last4Controller.dispose();
    expiryController.dispose();
    super.dispose();
  }

  Future<void> _orderCard(String type) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final user = profile.data() ?? {};
    await FirebaseFirestore.instance.collection('cardOrders').add({
      'userId': uid,
      'cardType': type,
      'holderName': user['name'] ?? '',
      'deliveryAddress': user['address'] ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${type == 'virtual' ? 'Virtual' : 'Physical'} card order submitted",
        ),
      ),
    );
  }

  Future<void> _addLinkedBankCard() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final last4 = last4Controller.text.trim();
    if (bankNameController.text.trim().isEmpty ||
        holderNameController.text.trim().isEmpty ||
        last4.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter bank, holder name, and last 4 digits'),
        ),
      );
      return;
    }
    final expiryParts = expiryController.text.trim().split('/');
    await FirebaseFirestore.instance.collection('linkedBankCards').add({
      'userId': uid,
      'bankName': bankNameController.text.trim(),
      'holderName': holderNameController.text.trim(),
      'network': network,
      'last4': last4,
      'maskedPan': '**** **** **** $last4',
      'expiryMonth': expiryParts.isNotEmpty ? expiryParts[0] : '',
      'expiryYear': expiryParts.length > 1 ? expiryParts[1] : '',
      'status': 'active',
      'tokenStatus': 'not_tokenized',
      'defaultForPayment': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    bankNameController.clear();
    holderNameController.clear();
    last4Controller.clear();
    expiryController.clear();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bank card added as a selectable payment source'),
      ),
    );
  }

  Future<void> _setDefaultPaymentSource({
    required String collection,
    required String id,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final firestore = FirebaseFirestore.instance;
    final issued = await firestore
        .collection('cards')
        .where('userId', isEqualTo: uid)
        .get();
    final linked = await firestore
        .collection('linkedBankCards')
        .where('userId', isEqualTo: uid)
        .get();
    final batch = firestore.batch();
    for (final doc in issued.docs) {
      batch.set(doc.reference, {
        'defaultForPayment': collection == 'cards' && doc.id == id,
      }, SetOptions(merge: true));
    }
    for (final doc in linked.docs) {
      batch.set(doc.reference, {
        'defaultForPayment': collection == 'linkedBankCards' && doc.id == id,
      }, SetOptions(merge: true));
    }
    batch.set(firestore.collection('users').doc(uid), {
      'defaultPaymentSource': {'collection': collection, 'id': id},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  void _showAddLinkedCardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add other bank card',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only masked card details are stored. A PCI-compliant processor must tokenize the card for live NFC/POS payments.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                _field('Bank name', bankNameController),
                _field('Card holder name', holderNameController),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Last 4 digits',
                        last4Controller,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _field('MM/YY', expiryController)),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: network,
                  decoration: _decor('Network'),
                  items: const ['Visa', 'Mastercard', 'Verve']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setSheetState(() => network = value ?? 'Visa'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _addLinkedBankCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Add Card'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Cards",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('cards')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          final cards = snap.data?.docs ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Virtual, physical, and bank cards",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Choose the card that powers POS/NFC payment intents.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              if (cards.isEmpty)
                _emptyCard()
              else
                ...cards.map((doc) => _card(doc.id, doc.data())),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _orderButton(
                      "Virtual",
                      Icons.credit_card,
                      () => _orderCard('virtual'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _orderButton(
                      "Physical",
                      Icons.local_shipping_outlined,
                      () => _orderCard('physical'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CardPaymentPage()),
                  ),
                  icon: const Icon(Icons.contactless),
                  label: const Text('NFC Tap to Pay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Other bank cards",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _showAddLinkedCardSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('linkedBankCards')
                    .where('userId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, linkedSnap) {
                  final linkedCards = linkedSnap.data?.docs ?? [];
                  if (linkedCards.isEmpty) {
                    return const Text(
                      "No linked bank cards yet",
                      style: TextStyle(color: Colors.black54),
                    );
                  }
                  return Column(
                    children: linkedCards
                        .map((doc) => _linkedCardTile(doc.id, doc.data()))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                "Orders",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('cardOrders')
                    .where('userId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, orderSnap) {
                  final orders = orderSnap.data?.docs ?? [];
                  if (orders.isEmpty) {
                    return const Text(
                      "No card orders yet",
                      style: TextStyle(color: Colors.black54),
                    );
                  }
                  return Column(
                    children: orders
                        .map((doc) => _orderTile(doc.data()))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "No active CENTRA card",
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            "Order a virtual or physical card to start.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String id, Map<String, dynamic> card) {
    final isVirtual = card['cardType'] == 'virtual';
    final isDefault = card['defaultForPayment'] == true;
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isVirtual ? const Color(0xFF1A1F2B) : const Color(0xFF0A6E79),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isVirtual ? "Virtual Card" : "Physical ATM Card",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            card['maskedPan'] ?? "**** **** **** ----",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card['holderName'] ?? "Card Holder",
                style: const TextStyle(color: Colors.white),
              ),
              InkWell(
                onTap: () =>
                    _setDefaultPaymentSource(collection: 'cards', id: id),
                child: Text(
                  isDefault ? "Default" : card['status'] ?? "active",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkedCardTile(String id, Map<String, dynamic> card) {
    final isDefault = card['defaultForPayment'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7F6F7),
          foregroundColor: Color(0xFF0A6E79),
          child: Icon(Icons.account_balance),
        ),
        title: Text(
          "${card['bankName'] ?? 'Bank'} ${card['network'] ?? 'Card'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${card['maskedPan'] ?? '****'} • ${card['tokenStatus'] ?? 'not_tokenized'}",
        ),
        trailing: TextButton(
          onPressed: () =>
              _setDefaultPaymentSource(collection: 'linkedBankCards', id: id),
          child: Text(isDefault ? 'Default' : 'Set default'),
        ),
      ),
    );
  }

  Widget _orderButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF0A6E79)),
        label: Text(
          "Order $label",
          style: const TextStyle(
            color: Color(0xFF0A6E79),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(
          "${order['cardType'] ?? 'card'} card",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(order['deliveryAddress'] ?? ''),
        trailing: Text(
          order['status'] ?? 'pending',
          style: const TextStyle(
            color: Color(0xFF0A6E79),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: _decor(label),
      ),
    );
  }

  InputDecoration _decor(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0A6E79)),
      ),
    );
  }
}
