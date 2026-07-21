import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../providers/auth_provider.dart';
import '../widgets/otp_code_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _prefilledEmail = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill (but keep editable) from the email passed by ForgotPasswordScreen;
    // only run once so we don't clobber user edits on subsequent rebuilds.
    if (!_prefilledEmail) {
      final extra = GoRouterState.of(context).extra;
      if (extra is String) {
        _emailController.text = extra;
      }
      _prefilledEmail = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _error = null);
      await context.read<AuthProvider>().resetPassword(
            email: _emailController.text,
            code: _codeController.text,
            newPassword: _passwordController.text,
          );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((value) => value.isBusy);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (!text.contains('@')) return 'Email chưa đúng định dạng.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  OtpCodeField(controller: _codeController, labelText: 'Mã xác nhận'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                    validator: (value) =>
                        (value?.length ?? 0) < 6 ? 'Mật khẩu tối thiểu 6 ký tự.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                    validator: (value) =>
                        value != _passwordController.text ? 'Mật khẩu xác nhận không khớp.' : null,
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
                  : const Text('Đặt lại mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}
