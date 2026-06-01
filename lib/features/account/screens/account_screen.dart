import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pairing/providers/pairing_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final session = auth.session;
    final profile = session.profile;
    final partner = session.partner;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?.displayName ?? 'Chưa có tên',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(session.user?.email ?? ''),
                  const SizedBox(height: 12),
                  Text('Trạng thái: ${session.isPaired ? 'Đã ghép đôi' : 'Chưa ghép đôi'}'),
                  if (partner != null) Text('Partner: ${partner.email}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.go('/profile-setup'),
            icon: const Icon(Icons.edit),
            label: const Text('Sửa hồ sơ'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/order-history'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.active,
              side: const BorderSide(color: AppColors.active),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Lịch sử mua quà'),
          ),
          if (session.isPaired) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _disconnect(context),
              icon: const Icon(Icons.link_off),
              label: const Text('Hủy kết nối partner'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect(BuildContext context) async {
    try {
      await context.read<PairingProvider>().disconnect();
      if (context.mounted) context.go('/pairing');
    } on ApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
