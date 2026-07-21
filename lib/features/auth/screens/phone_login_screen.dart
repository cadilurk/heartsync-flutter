import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final digits = _phoneController.text.trim().replaceFirst(RegExp(r'^0+'), '');
    final fullPhoneNumber = '+84$digits';

    final auth = context.read<AuthProvider>();
    await auth.startPhoneLogin(fullPhoneNumber);
    if (!mounted) return;
    if (auth.phoneVerificationId != null) {
      context.go('/otp-verify', extra: fullPhoneNumber);
    } else {
      setState(() => _error = auth.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((value) => value.isBusy);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập bằng số điện thoại'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Nhập số điện thoại để nhận mã OTP.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Text('+84', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Số điện thoại'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Vui lòng nhập số điện thoại.';
                        if (!RegExp(r'^0?[0-9]{9,10}$').hasMatch(text)) {
                          return 'Số điện thoại chưa đúng định dạng.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
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
                  : const Text('Gửi mã OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
