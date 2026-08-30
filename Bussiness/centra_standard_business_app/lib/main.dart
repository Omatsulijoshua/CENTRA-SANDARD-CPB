import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const ProviderScope(child: CentraBusinessApp()));
}

class AuthModeNotifier extends Notifier<LoginMode> {
  @override
  LoginMode build() => LoginMode.owner;

  set state(LoginMode value) => super.state = value;
}

final authModeProvider = NotifierProvider<AuthModeNotifier, LoginMode>(AuthModeNotifier.new);

enum LoginMode { owner, employee }

class CentraBusinessApp extends ConsumerWidget {
  const CentraBusinessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const BusinessOnboardingPage(),
        ),
        GoRoute(path: '/owner', builder: (_, __) => const OwnerDashboardPage()),
        GoRoute(
          path: '/employee',
          builder: (_, __) => const EmployeeDashboardPage(),
        ),
        GoRoute(
          path: '/receive-nfc',
          builder: (_, __) => const NfcReceivePage(),
        ),
        GoRoute(path: '/employees', builder: (_, __) => const EmployeesPage()),
      ],
    );

    return MaterialApp.router(
      title: 'Centra Standard Business',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6B5E)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() => context.go('/login'));
    return const Scaffold(
      body: Center(
        child: Text(
          'CENTRA BUSINESS',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(authModeProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 28),
            const Text(
              'Centra Standard Business',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Owners control everything. Employees receive and verify payments only.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 28),
            SegmentedButton<LoginMode>(
              segments: const [
                ButtonSegment(value: LoginMode.owner, label: Text('Owner')),
                ButtonSegment(
                  value: LoginMode.employee,
                  label: Text('Employee'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (value) =>
                  ref.read(authModeProvider.notifier).state = value.first,
            ),
            const SizedBox(height: 20),
            _GlassCard(
              child: Column(
                children: [
                  TextField(
                    decoration: _input(
                      mode == LoginMode.owner
                          ? 'Email or CPB profile phone'
                          : 'Employee phone',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: _input(
                      mode == LoginMode.owner ? 'Password' : 'Employee PIN',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go(
                      mode == LoginMode.owner ? '/owner' : '/employee',
                    ),
                    child: Text(
                      mode == LoginMode.owner
                          ? 'Sign in as Owner'
                          : 'Sign in as Employee',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (mode == LoginMode.owner)
              OutlinedButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('New business onboarding'),
              ),
            if (mode == LoginMode.employee)
              const _SecurityNote(
                text:
                    'Employees cannot sign up themselves. Business owners create employee receive-only profiles.',
              ),
          ],
        ),
      ),
    );
  }
}

class BusinessOnboardingPage extends StatefulWidget {
  const BusinessOnboardingPage({super.key});

  @override
  State<BusinessOnboardingPage> createState() => _BusinessOnboardingPageState();
}

class _BusinessOnboardingPageState extends State<BusinessOnboardingPage> {
  int step = 0;

  final titles = const [
    'Business Information',
    'Owner Verification',
    'Banking Setup',
    'Employee Setup',
    'Security Setup',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business onboarding')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          LinearProgressIndicator(value: (step + 1) / titles.length),
          const SizedBox(height: 18),
          Text(
            titles[step],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _GlassCard(child: _stepFields()),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => setState(
              () => step == titles.length - 1 ? context.go('/owner') : step++,
            ),
            child: Text(
              step == titles.length - 1 ? 'Finish onboarding' : 'Continue',
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepFields() {
    final fields = switch (step) {
      0 => [
        'Business name',
        'CAC registration',
        'Category',
        'Tax ID',
        'Address',
        'Branch count',
      ],
      1 => ['BVN', 'NIN', 'Selfie verification URL', 'Utility bill URL'],
      2 => ['Settlement bank', 'Settlement account', 'Activate NFC payments'],
      3 => ['First employee name', 'Employee phone', 'Daily limit'],
      _ => ['Transaction PIN', 'Enable biometrics', 'Trusted device name'],
    };
    return Column(
      children: fields
          .map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(decoration: _input(field)),
            ),
          )
          .toList(),
    );
  }
}

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _BalanceHero(
            title: 'Business Balance',
            amount: 'NGN 12,450,000',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionCard(
                icon: Icons.people_alt,
                title: 'Employees',
                onTap: () => context.go('/employees'),
              ),
              _ActionCard(
                icon: Icons.nfc,
                title: 'NFC Receive',
                onTap: () => context.go('/receive-nfc'),
              ),
              _ActionCard(
                icon: Icons.analytics_outlined,
                title: 'Analytics',
                onTap: () {},
              ),
              _ActionCard(
                icon: Icons.security,
                title: 'Fraud Center',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Live employee activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const _TransactionTile(
            title: 'John David received payment',
            amount: '+NGN 42,000',
            status: 'NFC tap success',
          ),
          const _TransactionTile(
            title: 'Ada Branch QR payment',
            amount: '+NGN 18,500',
            status: 'Verified',
          ),
        ],
      ),
    );
  }
}

class EmployeeDashboardPage extends StatelessWidget {
  const EmployeeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Receive Mode')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _BalanceHero(
            title: 'Centra Fashion Hub - John David',
            amount: 'Receive-only account',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/receive-nfc'),
            icon: const Icon(Icons.nfc),
            label: const Text('Receive with NFC'),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.qr_code),
            label: const Text('Show payment QR'),
          ),
          const SizedBox(height: 18),
          const _SecurityNote(
            text:
                'Employee access is receive-only. Withdrawals, transfers, business settings, and wallet secrets are blocked.',
          ),
          const _TransactionTile(
            title: 'Customer transfer confirmed',
            amount: '+NGN 9,800',
            status: 'Bank transfer',
          ),
        ],
      ),
    );
  }
}

class NfcReceivePage extends StatefulWidget {
  const NfcReceivePage({super.key});

  @override
  State<NfcReceivePage> createState() => _NfcReceivePageState();
}

class _NfcReceivePageState extends State<NfcReceivePage>
    with SingleTickerProviderStateMixin {
  final amount = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    amount.dispose();
    pulse.dispose();
    super.dispose();
  }

  Future<void> _startReceive() async {
    final value = double.tryParse(amount.text.trim()) ?? 0;
    if (value <= 0 || value > 100000) {
      _show('Amount must be between NGN 1 and NGN 100,000');
      return;
    }
    final ok = await auth.authenticate(
      localizedReason: 'Authorize this device to receive payment',
      options: const AuthenticationOptions(biometricOnly: false),
    );
    if (!ok || !mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: _SecurityNote(
          text:
              'NFC session created. Customer taps card/phone. Customer PIN or biometric must happen on their own device or PCI-compliant provider screen only.',
        ),
      ),
    );
  }

  void _show(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Payment')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          ScaleTransition(
            scale: Tween<double>(
              begin: 0.94,
              end: 1.04,
            ).animate(CurvedAnimation(parent: pulse, curve: Curves.easeInOut)),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Center(
                child: Icon(Icons.nfc, size: 96, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: _input('Amount to receive'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _startReceive,
            icon: const Icon(Icons.contactless),
            label: const Text('Activate NFC receive'),
          ),
          const SizedBox(height: 12),
          const _SecurityNote(
            text:
                'Limits: NGN 100,000 per transaction and NGN 500,000 daily. Fraud scoring checks device, velocity, and location anomalies.',
          ),
        ],
      ),
    );
  }
}

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Create employee'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _EmployeeTile(
            name: 'John David',
            account: 'Centra Fashion Hub - John David',
            status: 'Active NFC receive',
          ),
          _EmployeeTile(
            name: 'Ada Okoro',
            account: 'Centra Fashion Hub - Ada Okoro',
            status: 'QR + bank transfer',
          ),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.name,
    required this.account,
    required this.status,
  });
  final String name;
  final String account;
  final String status;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('$account\n$status'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.title, required this.amount});
  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF061A18), Color(0xFF0B6B5E)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: _GlassCard(
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.title,
    required this.amount,
    required this.status,
  });
  final String title;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F7EF),
          child: Icon(Icons.arrow_downward, color: Color(0xFF0B6B5E)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(status),
        trailing: Text(
          amount,
          style: const TextStyle(
            color: Color(0xFF0B6B5E),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF0B4A42), height: 1.35),
      ),
    );
  }
}

InputDecoration _input(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}
