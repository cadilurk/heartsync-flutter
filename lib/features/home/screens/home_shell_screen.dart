import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../account/screens/account_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../store/screens/store_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isPaired = context.watch<AuthProvider>().isPaired;
    final pages = [
      const _HomeTab(),
      const _GuardedCoupleTab(title: 'Heart Alarm', icon: Icons.notifications_none),
      const _GuardedCoupleTab(title: 'Heart Map', icon: Icons.map_outlined),
      const _GuardedCoupleTab(title: 'Heart Space', icon: Icons.image_outlined),
      const _GuardedCoupleTab(title: 'Challenges', icon: Icons.emoji_events_outlined),
      const StoreScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          final restricted = index >= 1 && index <= 4;
          if (restricted && !isPaired) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bạn cần ghép đôi trước khi dùng tính năng này.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
            setState(() => _index = 0);
            return;
          }
          setState(() => _index = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Alarm'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.image_outlined), label: 'Space'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Challenges'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    final startDate = session.relationship?.relationshipStartDate ??
        session.profile?.relationshipStartDate ??
        DateTime.now();
    final days = DateTime.now().difference(startDate).inDays.abs();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Our Love Story',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.title,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFEE5AA6), Color(0xFFF85787), Color(0xFFA63EE8)],
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 62),
              const SizedBox(height: 12),
              const Text('We have been together for',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              Text(
                '$days',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 68,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const Text('days', style: TextStyle(color: Colors.white, fontSize: 22)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.link, color: AppColors.active),
            title: Text(session.partner == null ? 'Chưa có partner' : 'Đã kết nối partner'),
            subtitle: Text(session.partner?.email ?? 'Các tính năng couple sẽ mở sau khi ghép đôi.'),
          ),
        ),
      ],
    );
  }
}

class _GuardedCoupleTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _GuardedCoupleTab({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.active),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Dev khác có thể build tiếp tính năng này bằng currentUser, partner và relationship từ AuthProvider.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

