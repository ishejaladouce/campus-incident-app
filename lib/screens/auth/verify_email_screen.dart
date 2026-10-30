import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Check automatically every 5 seconds if the user clicked the link
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      context.read<AuthProvider>().checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkNow() async {
    final verified = await context.read<AuthProvider>().checkEmailVerified();
    if (!verified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not verified yet. Please check your inbox.')),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.resendVerificationEmail();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Verification email sent!' : auth.error ?? 'Could not send email')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.profile?.email ?? 'your ALU email';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80),
              const SizedBox(height: 16),
              Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification link to $email. '
                'Open it, then come back here. (Check your spam folder too!)',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(label: "I've verified my email", onPressed: _checkNow, isLoading: auth.isLoading),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _resend, child: const Text('Resend email')),
              TextButton(onPressed: auth.logout, child: const Text('Use a different account')),
            ],
          ),
        ),
      ),
    );
  }
}