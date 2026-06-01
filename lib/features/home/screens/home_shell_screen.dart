import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/overlay/overlay_manager.dart';
import '../../account/screens/account_screen.dart';
import '../../alarm/screens/alarm_screen.dart';
import '../../auth/providers/auth_provider.dart';

import '../../alarm/providers/alarm_provider.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OverlayManager().init(context);
        context.read<AlarmProvider>().fetchUnreadSignals();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AlarmProvider>().fetchUnreadSignals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaired = context.watch<AuthProvider>().isPaired;
    final unreadCount = context.watch<AlarmProvider>().unreadCount;

    final pages = [
      const _HomeTab(),
      const AlarmScreen(),
      const _GuardedCoupleTab(title: 'Heart Map', icon: Icons.map_outlined),
      const _GuardedCoupleTab(title: 'Heart Space', icon: Icons.image_outlined),
      const _GuardedCoupleTab(title: 'Challenges', icon: Icons.emoji_events_outlined),
      const _StoreTab(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          final restricted = index >= 1 && index <= 4;
          if (restricted && !isPaired) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bạn cần ghép đôi trước khi dùng tính năng này.')),
            );
            setState(() => _index = 0);
            return;
          }
          setState(() => _index = index);
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Home'),
          NavigationDestination(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_none),
            ),
            label: 'Alarm',
          ),
          const NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          const NavigationDestination(icon: Icon(Icons.image_outlined), label: 'Space'),
          const NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Challenges'),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Store'),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
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

class _StoreTab extends StatelessWidget {
  const _StoreTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Heart Store', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.inventory_2_outlined),
            title: Text('Gift suggestions'),
            subtitle: Text('Store không bắt buộc paired trong MVP, nhưng vẫn có auth guard.'),
          ),
        ),
      ],
    );
  }
}
