import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

class PairingSuccessScreen extends StatelessWidget {
  const PairingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partner = context.watch<AuthProvider>().session.partner;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.favorite, size: 86, color: Color(0xFFF43F7B)),
              const SizedBox(height: 16),
              const Text(
                'Ghép đôi thành công!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                partner == null ? 'Hai tài khoản đã được kết nối.' : 'Partner: ${partner.email}',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Vào Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
