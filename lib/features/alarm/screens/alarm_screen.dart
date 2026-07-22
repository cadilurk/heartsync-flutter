import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/alarm_provider.dart';

// ── Signal display data ───────────────────────────────────────────────────────

class _SignalData {
  final Color bg;
  final Color border;
  final Color heartColor;
  final Color textColor;
  final String emoji;
  final String label;

  const _SignalData({
    required this.bg,
    required this.border,
    required this.heartColor,
    required this.textColor,
    required this.emoji,
    required this.label,
  });
}

const _data = <SignalType, _SignalData>{
  SignalType.miss: _SignalData(
    bg: Color(0xFFF3E8FF),
    border: Color(0xFFC084FC),
    heartColor: Color(0xFFC084FC),
    textColor: Color(0xFF9333EA),
    emoji: '🥺',
    label: 'Nhớ lắm',
  ),
  SignalType.care: _SignalData(
    bg: Color(0xFFFFF7ED),
    border: Color(0xFFFB923C),
    heartColor: Color(0xFFFB923C),
    textColor: Color(0xFFEA580C),
    emoji: '🤗',
    label: 'Nghĩ đến em',
  ),
  SignalType.love: _SignalData(
    bg: Color(0xFFFFF0F5),
    border: Color(0xFFEC4899),
    heartColor: Color(0xFFEC4899),
    textColor: Color(0xFFEC4899),
    emoji: '💕',
    label: 'Yêu lắm',
  ),
};

// ── Heart CustomPainter ───────────────────────────────────────────────────────

class _HeartPainter extends CustomPainter {
  final Color color;
  const _HeartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 36;
    final sy = size.height / 36;

    double x(double v) => v * sx;
    double y(double v) => v * sy;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(x(18), y(30))
      ..cubicTo(x(18), y(30), x(4), y(21), x(4), y(12))
      ..arcToPoint(Offset(x(18), y(12)),
          radius: Radius.elliptical(x(7), y(7)), clockwise: true)
      ..arcToPoint(Offset(x(32), y(12)),
          radius: Radius.elliptical(x(7), y(7)), clockwise: true)
      ..cubicTo(x(32), y(21), x(18), y(30), x(18), y(30))
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) => old.color != color;
}

// ── Main screen ───────────────────────────────────────────────────────────────

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _idleAnim;
  late final Animation<double> _beatAnim;

  bool _wasReceiving = false;
  AlarmProvider? _alarm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _alarm = context.read<AlarmProvider>();
  }

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _idleAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _beatAnim = Tween<double>(begin: 0.82, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final alarm = context.read<AlarmProvider>();
      alarm.startShakeDetection();
      alarm.onPartnerOfflineCallback = _showOfflineSnackbar;
    });
  }

  void _syncAnimation(bool isReceiving) {
    if (isReceiving == _wasReceiving) return;
    _wasReceiving = isReceiving;
    _pulseCtrl.stop();
    _pulseCtrl.duration = isReceiving
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 1200);
    _pulseCtrl.repeat(reverse: true);
  }

  void _showOfflineSnackbar() {
    if (!mounted) return;
    final session = context.read<AuthProvider>().session;
    final name = session.partnerDisplayName ?? _name(session.partner?.email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💔 $name đang offline rồi~'),
        backgroundColor: const Color(0xFFFF4B72),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String _name(String? email) {
    if (email == null || email.isEmpty) return 'Partner';
    return email.split('@').first;
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _alarm?.stopShakeDetection();
    _alarm?.onPartnerOfflineCallback = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarm = context.watch<AlarmProvider>();
    final session = context.watch<AuthProvider>().session;
    final partner = session.partner;
    final isReceiving = alarm.isReceiving;
    final selected = alarm.selectedSignalType;

    _syncAnimation(isReceiving);

    final heartAnim = isReceiving ? _beatAnim : _idleAnim;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Rung chuông Yêu thương',
          style: TextStyle(
            color: Color(0xFF231B1E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 210,
              height: 210,
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
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE3EC).withValues(alpha: 0.5),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // A. Partner Header Card
                  _PartnerHeaderCard(
                    name: session.partnerDisplayName ?? _name(partner?.email),
                    email: partner?.email ?? '',
                    avatarUrl: session.partnerProfile?.avatarUrl,
                    isConnected: alarm.isConnected,
                  ),

                  const SizedBox(height: 28),

                  // B. Signal Cards Selection
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: SignalType.values.map((type) {
                      final isActive = type == selected;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: type.index == 0 ? 0 : 4,
                            right: type.index == SignalType.values.length - 1 ? 0 : 4,
                          ),
                          child: _SignalCard(
                            signalData: _data[type]!,
                            isActive: isActive,
                            heartAnim: isActive ? heartAnim : null,
                            onTap: () => alarm.selectSignal(type),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // C. Page indicator dots
                  _PageDots(
                    current: selected.index,
                    activeColor: _data[selected]!.border,
                  ),

                  const SizedBox(height: 28),

                  // D. Big Pulsing Send Button
                  ScaleTransition(
                    scale: heartAnim,
                    child: GestureDetector(
                      onTap: () => alarm.sendAlarmWithType(selected),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _data[selected]!.border,
                              _data[selected]!.heartColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _data[selected]!.heartColor.withValues(alpha: 0.45),
                              blurRadius: 24,
                              spreadRadius: 4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _data[selected]!.emoji,
                              style: const TextStyle(fontSize: 38),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'GỬI NGAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Instruction Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD4E0), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.vibration_rounded,
                          color: Color(0xFFFF4B72),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chạm nút hoặc lắc máy để gửi "${_data[selected]!.label}"',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF70525A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // E. Recent Chips
                  _RecentChips(
                    lastSentAt: alarm.lastSentAt,
                    lastReceivedAt: alarm.lastReceivedAt,
                    fmt: _fmt,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Partner Header Card ─────────────────────────────────────────────────────────

class _PartnerHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isConnected;

  const _PartnerHeaderCard({
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          // Avatar — real Cloudinary photo if the partner has one, else the
          // gradient-initial fallback.
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF537B), Color(0xFFFF8DA1)],
              ),
            ),
            child: Center(
              child: (avatarUrl?.isNotEmpty ?? false)
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) => Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF231B1E),
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF887A80),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Online / Offline Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isConnected ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? const Color(0xFF15803D) : const Color(0xFF6B7280),
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

// ── Signal Card Widget ────────────────────────────────────────────────────────

class _SignalCard extends StatelessWidget {
  final _SignalData signalData;
  final bool isActive;
  final Animation<double>? heartAnim;
  final VoidCallback onTap;

  const _SignalCard({
    required this.signalData,
    required this.isActive,
    required this.heartAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: signalData.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? signalData.border : signalData.border.withValues(alpha: 0.3),
              width: isActive ? 2.2 : 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: signalData.heartColor.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji
              Text(
                signalData.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 8),

              // Heart Icon
              _HeartIcon(
                color: signalData.heartColor,
                scaleAnim: heartAnim,
              ),

              const SizedBox(height: 8),

              // Label
              Text(
                signalData.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: signalData.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartIcon extends StatelessWidget {
  final Color color;
  final Animation<double>? scaleAnim;

  const _HeartIcon({required this.color, required this.scaleAnim});

  @override
  Widget build(BuildContext context) {
    final heart = CustomPaint(
      size: const Size(32, 32),
      painter: _HeartPainter(color),
    );

    if (scaleAnim != null) {
      return ScaleTransition(scale: scaleAnim!, child: heart);
    }
    return heart;
  }
}

// ── Page Dots Widget ──────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int current;
  final Color activeColor;

  const _PageDots({required this.current, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(SignalType.values.length, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : const Color(0xFFFFD4E0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Recent Chips Widget ───────────────────────────────────────────────────────

class _RecentChips extends StatelessWidget {
  final DateTime? lastSentAt;
  final DateTime? lastReceivedAt;
  final String Function(DateTime) fmt;

  const _RecentChips({
    required this.lastSentAt,
    required this.lastReceivedAt,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    if (lastSentAt == null && lastReceivedAt == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (lastSentAt != null) _Chip(text: '💌 Đã gửi: ${fmt(lastSentAt!)}'),
        if (lastReceivedAt != null) _Chip(text: '💕 Đã nhận: ${fmt(lastReceivedAt!)}'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD4E0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFFFF4B72),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}