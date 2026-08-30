import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';

class TransferPage extends StatefulWidget {
  final String? prefillBank;
  final String? prefillAccountNumber;
  final String? prefillName;

  const TransferPage({
    super.key,
    this.prefillBank,
    this.prefillAccountNumber,
    this.prefillName,
  });

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  bool loading = false;
  bool previewing = false;
  bool transactionConfirmed = false;

  String? selectedBank;
  String receiverName = '';
  String receiverAccount = '';
  bool isInternal = false;
  double transferAmount = 0;

  final List<String> bankList = [
    "Central Standard CPB",
    "Access Bank",
    "UBA",
    "GTBank",
    "Zenith Bank",
    "First Bank",
    "Kuda",
    "Opay",
    "PalmPay",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefillBank != null) selectedBank = widget.prefillBank;
    if (widget.prefillAccountNumber != null) {
      accountNumberController.text = widget.prefillAccountNumber!;
    }
    if (widget.prefillName != null) receiverName = widget.prefillName!;
  }

  Future<void> resolveAccount() async {
    final accountNumber = accountNumberController.text.trim();
    if (accountNumber.length < 10 || selectedBank == null) return;

    setState(() => loading = true);

    try {
      final response = await ApiService.resolveAccount(accountNumber, "000");
      if (response['statusCode'] == 200) {
        setState(() {
          receiverName = response['data']['accountName'];
          receiverAccount = accountNumber;
          isInternal = response['data']['internal'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['data']['error'] ?? "Account not found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching account: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> confirmTransfer() async {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await ApiService.sendMoney(receiverAccount, amount);
      if (response['statusCode'] == 200) {
        setState(() => transactionConfirmed = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['data']['error'] ?? "Transfer failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction failed: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bank Transfer",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: transactionConfirmed 
          ? _buildSuccessScreen() 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Bank Details"),
                  const SizedBox(height: 16),
                  _buildBankSelector(),
                  const SizedBox(height: 16),
                  _buildAccountNumberField(),
                  if (receiverName.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildReceiverCard(),
                    const SizedBox(height: 32),
                    _buildSectionTitle("Amount"),
                    const SizedBox(height: 16),
                    _buildAmountField(),
                    const SizedBox(height: 40),
                    _buildTransferButton(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
    );
  }

  Widget _buildBankSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Select Bank"),
          value: selectedBank,
          items: bankList.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
          onChanged: (value) {
            setState(() {
              selectedBank = value;
              receiverName = '';
            });
            if (accountNumberController.text.length == 10) resolveAccount();
          },
        ),
      ),
    );
  }

  Widget _buildAccountNumberField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: accountNumberController,
        onChanged: (val) {
          if (val.length == 10) {
            resolveAccount();
          } else {
            setState(() => receiverName = '');
          }
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Account Number",
          suffixIcon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
        ),
        keyboardType: TextInputType.number,
        maxLength: 10,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      ),
    );
  }

  Widget _buildReceiverCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A6E79).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0A6E79).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A6E79),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiverName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF054C53)),
                ),
                Text(
                  "$selectedBank • $receiverAccount",
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0A6E79).withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          const Text("₦", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A6E79))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: amountController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(border: InputBorder.none, hintText: "0.00"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : confirmTransfer,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A6E79),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Text("Confirm Transfer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/Payment_Successfull.json', width: 220, repeat: false),
          const SizedBox(height: 24),
          const Text("Transfer Successful!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A6E79))),
          const SizedBox(height: 8),
          Text("Sent ₦${amountController.text} to $receiverName", style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A6E79),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Back to Home", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
