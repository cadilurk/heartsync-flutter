import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/overlay/overlay_manager.dart';
import '../../../core/network/api_client.dart';
import '../../account/screens/account_screen.dart';
import '../../alarm/screens/alarm_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../heart_map/screens/heart_map_screen.dart';
import '../providers/milestone_provider.dart';
import '../models/milestone.dart';
import 'milestone_dialog.dart';
import 'challenges_screen.dart';

import '../../alarm/providers/alarm_provider.dart';
import '../../space/screens/space_screen.dart';
import '../../store/screens/store_screen.dart';

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
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.read<AlarmProvider>().fetchUnreadSignals();
        });
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
      const HeartMapScreen(),
      const SpaceScreen(),
      const ChallengesScreen(),
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
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_none),
            ),
            selectedIcon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications),
            ),
            label: 'Alarm',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.image_outlined),
            selectedIcon: Icon(Icons.image),
            label: 'Space',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Challenges',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Store',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MilestoneProvider>().loadMilestones();
    });

    // Tăng bộ đếm kỉ niệm thêm 1 ngày sau mỗi 30 giây để test dễ dàng
    // Lưu sự thay đổi trực tiếp vào database bằng cách lùi ngày kỉ niệm gốc 1 ngày về quá khứ!
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (mounted) {
        try {
          final apiClient = context.read<ApiClient>();
          await apiClient.post<Map<String, dynamic>>(
            '/account/relationship/shift-date',
            null,
            (json) => json as Map<String, dynamic>,
          );
          
          if (mounted) {
            // Tải lại session mới nhất từ database (ngày kỉ niệm đã lùi về quá khứ 1 ngày)
            await context.read<AuthProvider>().refreshSession(notifyLoading: false);
          }
        } catch (e) {
          debugPrint('Error shifting anniversary date: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  void _showMilestoneDialog([Milestone? milestone]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MilestoneDialog(milestone: milestone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    final milestoneProvider = context.watch<MilestoneProvider>();

    final startDate = session.relationship?.relationshipStartDate ??
        session.profile?.relationshipStartDate ??
        DateTime.now();
    final totalDays = DateTime.now().difference(startDate).inDays.abs();

    // Tính toán số lượng kỉ niệm và thử thách đã hoàn thành từ dữ liệu thật
    final memoriesCount = milestoneProvider.milestones.where((m) => m.type == 'memory').length;
    final challengesCount = milestoneProvider.milestones.where((m) => m.type == 'challenge' && m.isCompleted).length;

    return RefreshIndicator(
      onRefresh: () => context.read<MilestoneProvider>().loadMilestones(),
      color: const Color(0xFFF35C9B),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. Big Gradient Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF35C9B).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFFEE5AA6), Color(0xFFF85787), Color(0xFFA63EE8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Heart Icon
                const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  "We've been together for",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalDays',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 76,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'days',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Stats Grid (Challenges & Memories)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Challenges',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.subtitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$challengesCount',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Memories',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.subtitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$memoriesCount',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Saved',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Section Header
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Color(0xFFF35C9B), size: 22),
              const SizedBox(width: 10),
              Text(
                'Important Milestones',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Milestone List
          if (milestoneProvider.isLoading && milestoneProvider.milestones.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator(color: AppColors.active)),
            )
          else if (milestoneProvider.milestones.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: const [
                  Icon(Icons.hourglass_empty_outlined, color: Colors.grey, size: 36),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có cột mốc nào được tạo.',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nhấn nút bên dưới để thêm khoảnh khắc kỉ niệm nhé!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: milestoneProvider.milestones.length,
              itemBuilder: (context, index) {
                final milestone = milestoneProvider.milestones[index];
                return GestureDetector(
                  onTap: () => _showMilestoneDialog(milestone),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // Milestone Icon Circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            milestone.icon,
                            style: const TextStyle(
                              fontSize: 22,
                              fontFamily: 'Apple Color Emoji',
                              fontFamilyFallback: ['Segoe UI Emoji', 'Noto Color Emoji', 'Android Emoji'],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Milestone Texts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                milestone.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.title,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    _formatDate(milestone.date),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: milestone.type == 'challenge'
                                          ? (milestone.isCompleted
                                              ? Colors.green.shade50
                                              : Colors.orange.shade50)
                                          : Colors.pink.shade50.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      milestone.type == 'challenge'
                                          ? (milestone.isCompleted ? 'Thử thách ✓' : 'Thử thách')
                                          : 'Kỉ niệm',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: milestone.type == 'challenge'
                                            ? (milestone.isCompleted ? Colors.green.shade700 : Colors.orange.shade700)
                                            : AppColors.active,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Arrow indicator
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // 5. Add Milestone Button
          ElevatedButton(
            onPressed: () => _showMilestoneDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF35C9B), // Matching the pink button in the screenshot
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              '+ Add New Milestone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
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

