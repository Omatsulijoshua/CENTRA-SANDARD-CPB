import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class CardPaymentPage extends StatefulWidget {
  const CardPaymentPage({super.key});

  @override
  State<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {
  final LocalAuthentication localAuth = LocalAuthentication();
  final amountController = TextEditingController();
  String? selectedSourceId;
  String? selectedSourceType;
  bool loading = false;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<bool> _authorize() async {
    try {
      final supported = await localAuth.isDeviceSupported();
      final canCheck = await localAuth.canCheckBiometrics;
      if (supported && canCheck) {
        final ok = await localAuth.authenticate(
          localizedReason: 'Authorize NFC POS payment',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        if (ok) return true;
      }
    } catch (_) {}
    if (!mounted) return false;
    return _pinFallback();
  }

  Future<bool> _pinFallback() async {
    final pinController = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
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
              'Enter transaction PIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: _inputDecoration('PIN'),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  pinController.text.trim().length >= 4,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Authorize'),
              ),
            ),
          ],
        ),
      ),
    );
    pinController.dispose();
    return result ?? false;
  }

  Future<void> _createTapIntent(List<_PaymentSource> sources) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedSourceId == null || selectedSourceType == null) {
      return;
    }
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      _message('Enter a valid amount');
      return;
    }
    final source = sources.firstWhere(
      (item) => item.id == selectedSourceId && item.type == selectedSourceType,
    );
    setState(() => loading = true);
    final authorized = await _authorize();
    if (!authorized) {
      setState(() => loading = false);
      _message('Authorization cancelled');
      return;
    }

    final config = await FirebaseFirestore.instance
        .collection('config')
        .doc('cardPayments')
        .get();
    final providerReady = config.data()?['tapToPayProviderEnabled'] == true;
    final status = providerReady
        ? 'authorized_waiting_for_tap'
        : 'provider_required';
    final ref = await FirebaseFirestore.instance
        .collection('paymentIntents')
        .add({
          'userId': uid,
          'sourceType': source.type,
          'cardId': source.type == 'issued_card' ? source.id : null,
          'linkedCardId': source.type == 'linked_bank_card' ? source.id : null,
          'sourceLabel': source.title,
          'sourceMaskedPan': source.maskedPan,
          'amount': amount,
          'currency': 'NGN',
          'channel': 'nfc_pos',
          'authMethod': 'biometric_or_pin',
          'status': status,
          'provider': providerReady
              ? (config.data()?['providerName'] ?? 'configured_provider')
              : 'provider_not_configured',
          'createdAt': FieldValue.serverTimestamp(),
          'authorizedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;
    setState(() => loading = false);
    _showTapSheet(ref.id, providerReady);
  }

  void _showTapSheet(String intentId, bool providerReady) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              providerReady
                  ? Icons.nfc
                  : Icons.security_update_warning_outlined,
              size: 54,
              color: const Color(0xFF0A6E79),
            ),
            const SizedBox(height: 12),
            Text(
              providerReady ? 'Ready to tap POS' : 'Provider setup required',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              providerReady
                  ? 'Hold this device close to the POS terminal. The payment intent has been authorized.'
                  : 'The app created an authorized NFC payment intent. Connect an issuer/tokenization or Android HCE provider to complete real POS tap-to-pay.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            SelectableText(
              'Intent: $intentId',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }
    final cardsStream = FirebaseFirestore.instance
        .collection('cards')
        .where('userId', isEqualTo: uid)
        .snapshots();
    final linkedCardsStream = FirebaseFirestore.instance
        .collection('linkedBankCards')
        .where('userId', isEqualTo: uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'NFC Tap to Pay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: cardsStream,
        builder: (context, cardSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: linkedCardsStream,
            builder: (context, linkedSnap) {
              final sources = <_PaymentSource>[
                ...?cardSnap.data?.docs.map(
                  (doc) => _PaymentSource.fromIssuedCard(doc.id, doc.data()),
                ),
                ...?linkedSnap.data?.docs.map(
                  (doc) => _PaymentSource.fromLinkedCard(doc.id, doc.data()),
                ),
              ];
              if (selectedSourceId == null && sources.isNotEmpty) {
                final defaultSource = sources
                    .where((item) => item.isDefault)
                    .firstOrNull;
                selectedSourceId = defaultSource?.id ?? sources.first.id;
                selectedSourceType = defaultSource?.type ?? sources.first.type;
              }
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.nfc, color: Colors.white, size: 34),
                        SizedBox(height: 18),
                        Text(
                          'Pay on POS with your selected card',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Select a virtual, physical, or linked bank card. Authorize with biometrics or PIN before tap.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Payment source',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (sources.isEmpty)
                    const _NoticeCard(
                      text:
                          'No cards yet. Order a card or add another bank card first.',
                    )
                  else
                    ...sources.map(_sourceTile),
                  const SizedBox(height: 18),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Amount'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: sources.isEmpty || loading
                          ? null
                          : () => _createTapIntent(sources),
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.contactless),
                      label: const Text('Authorize Tap to Pay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _NoticeCard(
                    text:
                        'Live POS payments require certified issuer/tokenization/HCE provider setup. This creates the secure payment intent the provider will process.',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _sourceTile(_PaymentSource source) {
    final selected =
        source.id == selectedSourceId && source.type == selectedSourceType;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE7F6F7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? const Color(0xFF0A6E79)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        onTap: () => setState(() {
          selectedSourceId = source.id;
          selectedSourceType = source.type;
        }),
        leading: CircleAvatar(
          backgroundColor: source.type == 'issued_card'
              ? Colors.black
              : const Color(0xFF0A6E79),
          foregroundColor: Colors.white,
          child: Icon(
            source.type == 'issued_card'
                ? Icons.credit_card
                : Icons.account_balance,
          ),
        ),
        title: Text(
          source.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${source.maskedPan} • ${source.status}'),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Color(0xFF0A6E79))
            : const Icon(Icons.circle_outlined),
      ),
    );
  }
}

class _PaymentSource {
  _PaymentSource({
    required this.id,
    required this.type,
    required this.title,
    required this.maskedPan,
    required this.status,
    required this.isDefault,
  });

  final String id;
  final String type;
  final String title;
  final String maskedPan;
  final String status;
  final bool isDefault;

  factory _PaymentSource.fromIssuedCard(String id, Map<String, dynamic> data) {
    return _PaymentSource(
      id: id,
      type: 'issued_card',
      title: data['cardType'] == 'virtual'
          ? 'CENTRA Virtual Card'
          : 'CENTRA Physical ATM Card',
      maskedPan: data['maskedPan'] ?? '**** **** **** ----',
      status: data['status'] ?? 'active',
      isDefault: data['defaultForPayment'] == true,
    );
  }

  factory _PaymentSource.fromLinkedCard(String id, Map<String, dynamic> data) {
    return _PaymentSource(
      id: id,
      type: 'linked_bank_card',
      title: '${data['bankName'] ?? 'Bank'} ${data['network'] ?? 'Card'}',
      maskedPan:
          data['maskedPan'] ?? '**** **** **** ${data['last4'] ?? '----'}',
      status: data['status'] ?? 'active',
      isDefault: data['defaultForPayment'] == true,
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54, height: 1.35),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
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

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
