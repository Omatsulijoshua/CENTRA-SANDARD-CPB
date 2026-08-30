import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SendMoneyPage extends StatefulWidget {
  const SendMoneyPage({super.key});

  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {
  final _receiverController = TextEditingController();
  final _amountController = TextEditingController();

  String receiverName = '';
  String receiverAccount = '';
  String? receiverUid;
  bool isInternal = false;
  bool loadingReceiver = false;
  bool loadingTransfer = false;
  bool transactionConfirmed = false;

  Future<void> resolveAccount() async {
    final accountNumberInput = _receiverController.text.trim();

    if (accountNumberInput.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account number must be 10 digits")),
      );
      return;
    }

    setState(() {
      loadingReceiver = true;
      receiverName = '';
      receiverAccount = '';
      receiverUid = null;
      isInternal = false;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('accountNumber', isEqualTo: accountNumberInput)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account not found")),
        );
        return;
      }

      final doc = snap.docs.first;
      final data = doc.data();

      setState(() {
        receiverUid = doc.id;
        receiverName = (data['name'] ?? '').toString();
        receiverAccount = accountNumberInput;
        isInternal = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching account: $e")),
      );
    } finally {
      setState(() => loadingReceiver = false);
    }
  }

  Future<void> confirmTransaction() async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid;
    if (senderUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login")));
      return;
    }
    if (receiverUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resolve receiver first")));
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }

    setState(() => loadingTransfer = true);

    try {
      await FirebaseFirestore.instance.runTransaction((t) async {
        final senderRef = FirebaseFirestore.instance.collection('users').doc(senderUid);
        final receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverUid);

        final senderSnap = await t.get(senderRef);
        await t.get(receiverRef);

        final senderBal = (senderSnap.data()?['balance'] ?? 0);
        final senderBalNum = senderBal is num ? senderBal.toDouble() : 0.0;
        if (senderBalNum < amount) throw Exception('Insufficient balance');

        t.update(senderRef, {
          'balance': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
          'totals.sendMoney': FieldValue.increment(amount),
          'totals.transactions': FieldValue.increment(1),
        });
        t.update(receiverRef, {
          'balance': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
          'totals.transactions': FieldValue.increment(1),
        });

        final senderTxRef = FirebaseFirestore.instance.collection('transactions').doc();
        final receiverTxRef = FirebaseFirestore.instance.collection('transactions').doc();

        t.set(senderTxRef, {
          'type': 'send_money',
          'amount': amount,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': senderUid,
          'direction': 'debit',
          'counterpartyUserId': receiverUid,
          'counterpartyAccount': receiverAccount,
          'counterpartyName': receiverName,
          'reference': senderTxRef.id,
        });

        t.set(receiverTxRef, {
          'type': 'send_money',
          'amount': amount,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': receiverUid,
          'direction': 'credit',
          'counterpartyUserId': senderUid,
          'counterpartyAccount': senderSnap.data()?['accountNumber'] ?? '',
          'counterpartyName': senderSnap.data()?['name'] ?? '',
          'reference': senderTxRef.id,
        });
      });

      setState(() => transactionConfirmed = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transaction failed: $e")));
    } finally {
      setState(() => loadingTransfer = false);
    }
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (transactionConfirmed) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/Payment_Successfull.json', width: 220, repeat: false),
                const SizedBox(height: 16),
                const Text("Send money successful", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("$receiverName • $receiverAccount", style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6E79),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Back to home", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Send Money"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("To", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _receiverController,
                      onChanged: (val) {
                        if (val.trim().length == 10) {
                          resolveAccount();
                        } else if (receiverName.isNotEmpty) {
                          setState(() {
                            receiverName = '';
                            receiverUid = null;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter 10-digit Account Number",
                        hintStyle: TextStyle(color: Colors.grey),
                        counterText: "",
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                    ),
                  ),
                  if (loadingReceiver)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (receiverName.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A6E79), Color(0xFF054C53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A6E79).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Account Name", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(receiverName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(receiverAccount, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isInternal ? "Internal" : "External", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("Amount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0A6E79).withOpacity(0.3), width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Text("₦", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A6E79))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(border: InputBorder.none, hintText: "Enter amount"),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: loadingTransfer ? null : confirmTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6E79),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: loadingTransfer
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
