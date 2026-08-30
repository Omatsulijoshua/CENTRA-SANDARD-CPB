import 'package:central_stadard_cpb/pages/deposit_page.dart';
import 'package:central_stadard_cpb/pages/transfer_page.dart';
import 'package:central_stadard_cpb/pages/TransactionList.dart' as tx_list;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => loading = false);
        return;
      }
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      if (mounted) {
        setState(() {
          userData = data;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A6E79),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome back!", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        userData?['name'] ?? "User",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildIconBadge(Icons.notifications),
                ],
              ),
            ),

            // Main Body
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 140),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: const [
                          ActionButtons(),
                          SizedBox(height: 20),
                          BannerCarousel(),
                          SizedBox(height: 14),
                          Expanded(child: tx_list.TransactionList()),
                        ],
                      ),
                    ),
                  ),

                  // Wallet Card
                  Positioned(
                    top: 10,
                    left: 20,
                    right: 20,
                    child: _buildWalletCard(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D94A3), Color(0xFF0A6E79)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const Icon(Iconsax.wallet_3, color: Colors.white70, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "₦${((userData?['balance'] is num) ? (userData?['balance'] as num).toDouble() : 0.0).toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(userData?['accountNumber'] ?? "0000000000", style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(width: 8),
              const Icon(Icons.copy, color: Colors.white54, size: 14),
              const Spacer(),
              _buildKycBadge(),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKycBadge() {
    final status = userData?['kycStatus'] ?? 'pending';
    final isVerified = status == 'verified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isVerified ? "KYC Verified" : "KYC Pending",
        style: TextStyle(color: isVerified ? Colors.greenAccent : Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class BannerCarousel extends StatelessWidget {
  const BannerCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('appBanners').where('active', isEqualTo: true).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final b = docs[i].data();
              return Container(
                width: MediaQuery.of(context).size.width - 64,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F8),
                  borderRadius: BorderRadius.circular(18),
                  image: (b['imageUrl'] ?? '').toString().isNotEmpty
                      ? DecorationImage(image: NetworkImage(b['imageUrl']), fit: BoxFit.cover, opacity: 0.18)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(b['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF054C53))),
                    const SizedBox(height: 4),
                    Text(b['subtitle'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ActionButtons extends StatefulWidget {
  const ActionButtons({super.key});

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  bool showMore = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAction(Iconsax.add, "Deposit", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositPage()))),
            _buildAction(Iconsax.arrow_swap_horizontal, "Transfer", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferPage()))),
            _buildAction(Iconsax.call, "Airtime", () {}),
            _buildAction(Iconsax.more, "More", () => setState(() => showMore = !showMore)),
          ],
        ),
        if (showMore) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAction(Iconsax.wifi_square, "Data", () {}),
              _buildAction(Iconsax.game, "Betting", () {}),
              _buildAction(Iconsax.flash_1, "Electricity", () {}),
              _buildAction(Iconsax.house, "TV", () {}),
            ],
          ),
        ]
      ],
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
            child: Icon(icon, size: 24, color: const Color(0xFF0A6E79)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }
}
