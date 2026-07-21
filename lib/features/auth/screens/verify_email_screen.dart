import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/otp_code_field.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _cooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _cooldownTimer;
  // A code was already sent server-side at register time, so the resend
  // button starts enabled (0s left) — only disabled after an explicit tap.
  int _secondsLeft = 0;
  String? _error;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    await auth.verifyEmailCode(_codeController.text);
    if (!mounted) return;
    if (auth.errorMessage != null) {
      setState(() => _error = auth.errorMessage);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    final auth = context.read<AuthProvider>();
    await auth.resendEmailCode();
    if (!mounted) return;
    setState(() => _error = auth.errorMessage);
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().session.user?.email;
    final isLoading = context.select<AuthProvider, bool>((value) => value.isBusy);

    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              email != null && email.isNotEmpty
                  ? 'Mã xác thực đã được gửi đến $email'
                  : 'Vui lòng xác thực email của bạn.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: OtpCodeField(controller: _codeController),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Xác nhận'),
            ),
            TextButton(
              onPressed: (isLoading || _secondsLeft > 0) ? null : _resend,
              child: Text(_secondsLeft > 0 ? 'Gửi lại mã (${_secondsLeft}s)' : 'Gửi lại mã'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
