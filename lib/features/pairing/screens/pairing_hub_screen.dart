import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

class PairingHubScreen extends StatelessWidget {
  const PairingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ghép đôi')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.favorite_border, size: 76, color: Color(0xFFF43F7B)),
              const SizedBox(height: 16),
              const Text(
                'Kết nối với người yêu của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tạo mã ghép đôi hoặc nhập mã partner gửi cho bạn.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/pairing/code'),
                child: const Text('Tạo mã ghép đôi'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/pairing/enter'),
                child: const Text('Nhập mã partner'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
