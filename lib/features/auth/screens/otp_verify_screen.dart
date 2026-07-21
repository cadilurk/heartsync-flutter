import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../providers/auth_provider.dart';
import '../widgets/otp_code_field.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const _cooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _cooldownTimer;
  int _secondsLeft = _cooldownSeconds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

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
    try {
      setState(() => _error = null);
      await context.read<AuthProvider>().submitPhoneOtp(_codeController.text);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _resend(String phoneNumber) async {
    if (_secondsLeft > 0) return;
    final auth = context.read<AuthProvider>();
    await auth.startPhoneLogin(phoneNumber);
    if (!mounted) return;
    setState(() => _error = auth.errorMessage);
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = GoRouterState.of(context).extra as String?;
    final isLoading = context.select<AuthProvider, bool>((value) => value.isBusy);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực OTP'),
        leading: BackButton(onPressed: () => context.go('/login-phone')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              phoneNumber != null ? 'Mã đã gửi đến $phoneNumber' : 'Mã xác thực đã được gửi.',
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
              onPressed: (isLoading || _secondsLeft > 0 || phoneNumber == null)
                  ? null
                  : () => _resend(phoneNumber),
              child: Text(_secondsLeft > 0 ? 'Gửi lại mã (${_secondsLeft}s)' : 'Gửi lại mã'),
            ),
          ],
        ),
      ),
    );
  }
}
