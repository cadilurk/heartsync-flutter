import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

    final displayName = profile?.displayName ?? 'Chưa cập nhật tên';
    final email = session.user?.email ?? '';
    final avatarUrl = profile?.avatarUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tài khoản cá nhân',
          style: TextStyle(
            color: Color(0xFF231B1E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient background glow circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE3EC).withValues(alpha: 0.7),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE3EC).withValues(alpha: 0.5),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // Profile Hero Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFDE8EE), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with heart badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF537B), Color(0xFFFF8DA1)],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: const Color(0xFFFFEEF3),
                              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : 'H',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF4B72),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4B72),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33FF4B72),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // User Display Name
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF231B1E),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // User Email
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF887A80),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Relationship Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: session.isPaired
                              ? const Color(0xFFFFF0F4)
                              : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: session.isPaired
                                ? const Color(0xFFFFD4E0)
                                : const Color(0xFFFFE082),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: session.isPaired
                                    ? const Color(0xFFFF4B72)
                                    : const Color(0xFFFFB300),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                session.isPaired
                                    ? Icons.favorite_rounded
                                    : Icons.heart_broken_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.isPaired ? 'Đã ghép đôi' : 'Chưa ghép đôi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: session.isPaired
                                          ? const Color(0xFFFF4B72)
                                          : const Color(0xFFE65100),
                                    ),
                                  ),
                                  if (session.isPaired && partner != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Nửa kia: ${partner.email}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B5860),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!session.isPaired)
                              GestureDetector(
                                onTap: () => context.go('/pairing'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4B72),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Ghép đôi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Section Title: Personal Info
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Cá nhân & Ứng dụng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A6B70),
                    ),
                  ),
                ),

                // Menu Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE8EE), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFFFF4B72),
                        iconBg: const Color(0xFFFFEEF3),
                        title: 'Sửa hồ sơ cá nhân',
                        subtitle: 'Cập nhật tên, ngày sinh, ngày yêu',
                        onTap: () => context.go('/profile-setup'),
                      ),
                      const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF4EAEE)),
                      _buildMenuItem(
                        icon: Icons.card_giftcard_rounded,
                        iconColor: const Color(0xFFFF6B4A),
                        iconBg: const Color(0xFFFFEEEA),
                        title: 'Lịch sử mua quà',
                        subtitle: 'Xem lại các đơn hàng quà tặng đã đặt',
                        onTap: () => context.push('/order-history'),
                      ),
                      if (session.isPaired) ...[
                        const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF4EAEE)),
                        _buildMenuItem(
                          icon: Icons.link_off_rounded,
                          iconColor: const Color(0xFFE53935),
                          iconBg: const Color(0xFFFFEBEE),
                          title: 'Hủy kết nối partner',
                          subtitle: 'Ngắt liên kết với tài khoản đối phương',
                          titleColor: const Color(0xFFE53935),
                          onTap: () => _confirmDisconnect(context),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Section Title: Account Options
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Tài khoản',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A6B70),
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE8EE), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildMenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFD32F2F),
                    iconBg: const Color(0xFFFFEBEE),
                    title: 'Đăng xuất',
                    subtitle: 'Thoát khỏi ứng dụng trên thiết bị này',
                    titleColor: const Color(0xFFD32F2F),
                    onTap: () => context.read<AuthProvider>().logout(),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: titleColor ?? const Color(0xFF231B1E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF887A80),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFC0B4B8),
        size: 22,
      ),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.heart_broken_rounded, color: Color(0xFFE53935)),
            SizedBox(width: 8),
            Text('Hủy kết nối?'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn hủy kết nối đôi với đối phương không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF7A6B70))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      _disconnect(context);
    }
  }

  Future<void> _disconnect(BuildContext context) async {
    try {
      await context.read<PairingProvider>().disconnect();
      if (context.mounted) context.go('/pairing');
    } on ApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

