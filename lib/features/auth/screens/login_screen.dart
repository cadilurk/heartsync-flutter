import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _error = null);
      await context.read<AuthProvider>().login(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    await auth.loginWithGoogle();
    if (!mounted) return;
    if (auth.errorMessage != null) {
      setState(() => _error = auth.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>(
      (value) => value.isBusy,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.favorite, color: Color(0xFFF43F7B), size: 64),
            const SizedBox(height: 16),
            const Text('Đăng nhập Heart Sync',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Vui lòng nhập email.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu.' : null,
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
                  : const Text('Đăng nhập'),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
            TextButton(
              onPressed: isLoading ? null : () => context.go('/forgot-password'),
              child: const Text('Quên mật khẩu?'),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('hoặc'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isLoading ? null : _submitGoogle,
              child: const Text('Tiếp tục với Google'),
            ),
            TextButton(
              onPressed: isLoading ? null : () => context.go('/login-phone'),
              child: const Text('Tiếp tục bằng số điện thoại'),
            ),
          ],
        ),
      ),
    );
  }
}
