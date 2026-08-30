import 'package:central_stadard_cpb/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({super.key});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  String accountName = "";
  String accountNumber = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUserDetails();
  }

  Future<void> loadUserDetails() async {
    try {
      final data = await ApiService.getProfile();
      setState(() {
        accountName = data["name"];
        accountNumber = data["accountNumber"];
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Receive Money", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.black)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text("Your Account Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF054C53))),
                  const SizedBox(height: 8),
                  const Text("Share these details to receive money", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 40),
                  _buildAccountCard(),
                  const SizedBox(height: 40),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          const Text("Central Standard Bank", style: TextStyle(color: Color(0xFF0A6E79), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Text(accountNumber, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFF1A1F2B))),
          const SizedBox(height: 12),
          Text(accountName.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleButton(Icons.copy, "Copy", () {
          Clipboard.setData(ClipboardData(text: accountNumber));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account number copied!")));
        }),
        _buildCircleButton(Icons.share, "Share", () {
          Share.share("Send money to:\n\nName: $accountName\nAccount Number: $accountNumber\nBank: Central Standard Bank");
        }),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0A6E79), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF0A6E79).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A6E79))),
      ],
    );
  }
}
