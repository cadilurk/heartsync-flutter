import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
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
import 'auto_slider_background.dart';

import '../../alarm/providers/alarm_provider.dart';
import '../../space/screens/space_screen.dart';
import '../../store/screens/store_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen>
    with WidgetsBindingObserver {
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
            label: 'Trang chủ',
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
            label: 'Báo hiệu',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Bản đồ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.image_outlined),
            selectedIcon: Icon(Icons.image),
            label: 'Kỷ niệm',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Thử thách',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Cửa hàng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
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

class _HomeTabState extends State<_HomeTab>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  DateTimeRange? _filterDateRange;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingPreviewUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MilestoneProvider>().loadMilestones();
    });

    _scrollController.addListener(() {
      if (mounted) setState(() => _scrollOffset = _scrollController.offset);
    });

    // Tăng bộ đếm kỉ niệm thêm 1 ngày sau mỗi 30 giây để test dễ dàng
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
            await context.read<AuthProvider>().refreshSession(
              notifyLoading: false,
            );
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
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(String? url) async {
    if (url == null) return;
    if (_playingPreviewUrl == url) {
      await _audioPlayer.stop();
      setState(() => _playingPreviewUrl = null);
    } else {
      await _audioPlayer.stop();
      setState(() => _playingPreviewUrl = url);
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingPreviewUrl = null);
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  Future<void> _selectFilterDate() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _filterDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
      helpText: 'CHỌN KHOẢNG THỜI GIAN KỶ NIỆM',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      saveText: 'ÁP DỤNG',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF35C9B), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _filterDateRange = picked);
    }
  }

  void _showMilestoneDialog([Milestone? milestone]) {
    final currentUserId = context.read<AuthProvider>().session.user?.id ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          MilestoneDialog(milestone: milestone, currentUserId: currentUserId),
    );
  }

  // Status config helper
  ({Color color, IconData icon, String label}) _statusConfig(String status) {
    switch (status) {
      case 'completed':
        return (
          color: const Color(0xFF22C55E),
          icon: Icons.check_circle,
          label: 'Hoàn thành ✅',
        );
      case 'declined':
        return (
          color: const Color(0xFFEF4444),
          icon: Icons.cancel,
          label: 'Từ chối ❌',
        );
      case 'negotiating':
        return (
          color: const Color(0xFF3B82F6),
          icon: Icons.chat_bubble_outline,
          label: 'Thương lượng 💬',
        );
      default:
        return (
          color: const Color(0xFFF59E0B),
          icon: Icons.hourglass_empty,
          label: 'Chờ xác nhận 🕐',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    final milestoneProvider = context.watch<MilestoneProvider>();

    final startDate =
        session.relationship?.relationshipStartDate ??
        session.profile?.relationshipStartDate ??
        DateTime.now();
    final totalDays = DateTime.now().difference(startDate).inDays.abs();

    final memoriesCount = milestoneProvider.milestones
        .where((m) => m.type == 'memory')
        .length;
    final completedCount = milestoneProvider.milestones
        .where((m) => m.isCompleted)
        .length;

    final displayMilestones = _filterDateRange == null
        ? milestoneProvider.milestones
        : milestoneProvider.milestones.where((m) {
            final dateOnly = DateTime(m.date.year, m.date.month, m.date.day);
            final startOnly = DateTime(
              _filterDateRange!.start.year,
              _filterDateRange!.start.month,
              _filterDateRange!.start.day,
            );
            final endOnly = DateTime(
              _filterDateRange!.end.year,
              _filterDateRange!.end.month,
              _filterDateRange!.end.day,
            );
            return dateOnly.compareTo(startOnly) >= 0 &&
                dateOnly.compareTo(endOnly) <= 0;
          }).toList();

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMilestoneDialog(),
        backgroundColor: const Color(0xFFF35C9B),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Thêm cột mốc',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<MilestoneProvider>().loadMilestones(),
        color: const Color(0xFFF35C9B),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── 1. Hero Header (parallax-like) ──────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeroSection(
                totalDays,
                memoriesCount,
                completedCount,
              ),
            ),

            // ── 2. Timeline label ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEE5AA6), Color(0xFFA63EE8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Dòng thời gian tình yêu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1B2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    if (_filterDateRange != null)
                      GestureDetector(
                        onTap: () => setState(() => _filterDateRange = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF35C9B,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _filterDateRange!.start.year == _filterDateRange!.end.year &&
                                        _filterDateRange!.start.month == _filterDateRange!.end.month &&
                                        _filterDateRange!.start.day == _filterDateRange!.end.day
                                    ? '${_filterDateRange!.start.day}/${_filterDateRange!.start.month}/${_filterDateRange!.start.year}'
                                    : '${_filterDateRange!.start.day}/${_filterDateRange!.start.month} - ${_filterDateRange!.end.day}/${_filterDateRange!.end.month}/${_filterDateRange!.end.year}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFF35C9B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.close,
                                size: 14,
                                color: Color(0xFFF35C9B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        _filterDateRange != null
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                        color: _filterDateRange != null
                            ? const Color(0xFFF35C9B)
                            : Colors.grey,
                      ),
                      onPressed: _selectFilterDate,
                      tooltip: 'Lọc từ ngày đến ngày',
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Timeline / Empty state ────────────────────────────────────
            if (milestoneProvider.isLoading &&
                milestoneProvider.milestones.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFF35C9B)),
                ),
              )
            else if (displayMilestones.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyTimeline())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final milestone = displayMilestones[index];
                    final isLeft = index.isEven;
                    return _buildTimelineNode(
                      milestone: milestone,
                      isLeft: isLeft,
                      isFirst: index == 0,
                      isLast: index == displayMilestones.length - 1,
                      screenWidth: screenWidth,
                    );
                  }, childCount: displayMilestones.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Hero Section ────────────────────────────────────────────────────────────

  Widget _buildHeroSection(
    int totalDays,
    int memoriesCount,
    int completedCount,
  ) {
    // Parallax: hero content moves slower than scroll
    final parallaxOffset = (_scrollOffset * 0.4).clamp(0.0, 60.0);

    return Container(
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        gradient: LinearGradient(
          colors: [Color(0xFFEE5AA6), Color(0xFFD946A8), Color(0xFFA63EE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40 - parallaxOffset * 0.3,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -20 + parallaxOffset * 0.2,
            left: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main content with parallax offset
          Transform.translate(
            offset: Offset(0, -parallaxOffset * 0.15),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '💕 HeartSync',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Couple',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Days counter
                    Text(
                      'Chúng mình đã bên nhau',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$totalDays',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: -4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'ngày',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        _heroStat(
                          '$memoriesCount',
                          'Kỉ niệm',
                          Icons.favorite_outline,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _heroStat(
                          '$completedCount',
                          'Hoàn thành',
                          Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' $label',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmptyTimeline() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF35C9B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              color: Color(0xFFF35C9B),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Dòng thời gian còn trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1B2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm cột mốc đầu tiên của hai người nhé!\nMỗi khoảnh khắc đều xứng đáng được ghi nhớ 💕',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline Node ────────────────────────────────────────────────────────────

  Widget _buildTimelineNode({
    required Milestone milestone,
    required bool isLeft,
    required bool isFirst,
    required bool isLast,
    required double screenWidth,
  }) {
    final sc = _statusConfig(milestone.status);
    final cardWidth =
        (screenWidth - 40 - 48 - 20) / 2; // 40 padding, 48 center col, 20 gap
    final typeIsMemory = milestone.type == 'memory';

    return GestureDetector(
      onTap: () => _showMilestoneDialog(milestone),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT CARD area
            SizedBox(
              width: cardWidth,
              child: isLeft
                  ? _buildScrapCard(milestone, sc, typeIsMemory)
                  : const SizedBox(),
            ),

            // CENTER: vertical line + dot
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  // Top line
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: isFirst
                            ? Colors.transparent
                            : const Color(0xFFE9D0E8),
                      ),
                    ),
                  ),
                  // Dot
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: sc.color, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: sc.color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      milestone.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // Bottom line
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: isLast
                            ? Colors.transparent
                            : const Color(0xFFE9D0E8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT CARD area
            SizedBox(
              width: cardWidth,
              child: !isLeft
                  ? _buildScrapCard(milestone, sc, typeIsMemory)
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrapCard(
    Milestone milestone,
    ({Color color, IconData icon, String label}) sc,
    bool typeIsMemory,
  ) {
    final urls = milestone.coverImageUrls.isNotEmpty
        ? milestone.coverImageUrls
        : (milestone.coverImageUrl != null
              ? [milestone.coverImageUrl!]
              : <String>[]);
    final actuallyHasCover = urls.isNotEmpty;
    final hasCover = actuallyHasCover; // alias for compatibility below
    final mood = _moods.where((m) => m.id == milestone.mood).firstOrNull;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: sc.color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: sc.color.withValues(alpha: 0.2), width: 1),
      ),
      child: Stack(
        children: [
          // Background carousel
          if (actuallyHasCover)
            Positioned.fill(child: AutoSliderBackground(imageUrls: urls)),
          // If has cover, add a gradient overlay for text readability
          if (hasCover)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.58),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Top area: Mood emoji if available
                if (mood != null) ...[
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 30),
                ] else if (hasCover) ...[
                  const SizedBox(height: 40),
                ],

                // Title
                Text(
                  milestone.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: hasCover ? Colors.white : const Color(0xFF1E1B2E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Date
                Text(
                  _formatDate(milestone.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: hasCover ? Colors.white70 : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Song
                if (milestone.songTitle != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: milestone.songPreviewUrl != null
                        ? () => _togglePreview(milestone.songPreviewUrl)
                        : null,
                    child: Row(
                      children: [
                        Icon(
                          _playingPreviewUrl == milestone.songPreviewUrl
                              ? Icons.pause_circle_filled
                              : Icons.music_note,
                          size: 12,
                          color: hasCover
                              ? Colors.white70
                              : Colors.purple.shade300,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            milestone.songTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: hasCover
                                  ? Colors.white70
                                  : Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (milestone.checklist.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 11,
                        color: hasCover
                            ? Colors.white70
                            : const Color(0xFFF35C9B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: milestone.progress,
                            minHeight: 5,
                            backgroundColor: hasCover
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFFFCE7F3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              hasCover ? Colors.white : const Color(0xFFF35C9B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${milestone.completedTaskCount}/${milestone.totalTaskCount}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: hasCover
                              ? Colors.white
                              : const Color(0xFFF35C9B),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: hasCover
                        ? sc.color.withValues(alpha: 0.2)
                        : sc.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: hasCover
                        ? Border.all(color: sc.color.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sc.icon, size: 9, color: sc.color),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          sc.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: sc.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mood {
  final String id;
  final String emoji;
  const _Mood(this.id, this.emoji);
}

const _moods = [
  _Mood('happy', '😄'),
  _Mood('emotional', '🥹'),
  _Mood('romantic', '🥰'),
  _Mood('excited', '🤩'),
  _Mood('happy_cry', '😭'),
  _Mood('nostalgic', '💭'),
];

class _GuardedCoupleTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _GuardedCoupleTab({required this.title, required this.icon});

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
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
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
