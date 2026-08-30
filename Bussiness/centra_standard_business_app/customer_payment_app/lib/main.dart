import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

void main() => runApp(const CustomerPayApp());

class CustomerPayApp extends StatelessWidget {
  const CustomerPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Centra Pay',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6B5E)),
      ),
      home: const CustomerPaymentApprovalPage(),
    );
  }
}

class CustomerPaymentApprovalPage extends StatefulWidget {
  const CustomerPaymentApprovalPage({super.key});

  @override
  State<CustomerPaymentApprovalPage> createState() =>
      _CustomerPaymentApprovalPageState();
}

class _CustomerPaymentApprovalPageState
    extends State<CustomerPaymentApprovalPage> {
  final auth = LocalAuthentication();
  bool approved = false;

  Future<void> approve() async {
    final ok = await auth.authenticate(
      localizedReason: 'Approve payment to Centra business merchant',
      options: const AuthenticationOptions(biometricOnly: false),
    );
    if (mounted) setState(() => approved = ok);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Approve Payment',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Customer authorization happens on this customer device or inside the certified payment SDK. Merchant devices never collect card PIN.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Centra Fashion Hub',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'NGN 42,000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: approve,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Approve with biometric / device PIN'),
            ),
            if (approved)
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Payment authorized securely'),
              ),
          ],
        ),
      ),
    );
  }
}
