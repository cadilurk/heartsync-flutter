import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
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

// ── Heart CustomPainter (SVG path M18 30s-14-9-14-18a7 7 0 0114 0 7 7 0 0114 0c0 9-14 18-14 18z)

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
      // M 18 30
      ..moveTo(x(18), y(30))
      // s -14 -9 -14 -18  (smooth cubic; prev is M so c1 = current point)
      ..cubicTo(x(18), y(30), x(4), y(21), x(4), y(12))
      // a 7 7 0 0 1 14 0
      ..arcToPoint(Offset(x(18), y(12)),
          radius: Radius.elliptical(x(7), y(7)), clockwise: true)
      // 7 7 0 0 1 14 0
      ..arcToPoint(Offset(x(32), y(12)),
          radius: Radius.elliptical(x(7), y(7)), clockwise: true)
      // c 0 9 -14 18 -14 18
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
    _beatAnim = Tween<double>(begin: 0.80, end: 1.30).animate(
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
    final partner = context.read<AuthProvider>().session.partner;
    final name = _name(partner?.email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💔 $name đang offline rồi~'),
        backgroundColor: AppColors.active,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _name(String? email) {
    if (email == null || email.isEmpty) return 'Partner';
    return email.split('@').first;
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _pulseCtrl.dispose();
    final alarm = context.read<AlarmProvider>();
    alarm.stopShakeDetection();
    alarm.onPartnerOfflineCallback = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarm = context.watch<AlarmProvider>();
    final partner = context.watch<AuthProvider>().session.partner;
    final isReceiving = alarm.isReceiving;
    final selected = alarm.selectedSignalType;

    _syncAnimation(isReceiving);

    final heartAnim = isReceiving ? _beatAnim : _idleAnim;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // A. Partner header
              _PartnerHeader(
                name: _name(partner?.email),
                isConnected: alarm.isConnected,
              ),

              const SizedBox(height: 32),

              // B. Signal cards
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

              const SizedBox(height: 14),

              // D. Instruction text
              Text(
                'Lắc điện thoại để gửi "${_data[selected]!.label}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF86868B),
                ),
              ),

              const SizedBox(height: 18),

              // E. Recent chips
              _RecentChips(
                lastSentAt: alarm.lastSentAt,
                lastReceivedAt: alarm.lastReceivedAt,
                fmt: _fmt,
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Partner header ─────────────────────────────────────────────────────────────

class _PartnerHeader extends StatelessWidget {
  final String name;
  final bool isConnected;

  const _PartnerHeader({required this.name, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1a1a2e),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected
                    ? const Color(0xFF22c55e)
                    : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isConnected ? 'Đang kết nối' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                color: isConnected
                    ? const Color(0xFF22c55e)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Signal card ────────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
          decoration: BoxDecoration(
            color: signalData.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: signalData.border, width: 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
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

              // Heart SVG via CustomPaint + optional ScaleTransition
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
                  fontSize: 10,
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
      size: const Size(36, 36),
      painter: _HeartPainter(color),
    );

    if (scaleAnim != null) {
      return ScaleTransition(scale: scaleAnim!, child: heart);
    }
    return heart;
  }
}

// ── Page dots ─────────────────────────────────────────────────────────────────

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
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: isActive ? 6 : 6,
          decoration: BoxDecoration(
            color: isActive ? activeColor : const Color(0xFFF4C0D1),
            borderRadius: BorderRadius.circular(isActive ? 4 : 50),
          ),
        );
      }),
    );
  }
}

// ── Recent chips ──────────────────────────────────────────────────────────────

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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (lastSentAt != null) _Chip(text: '💌 Đã gửi: ${fmt(lastSentAt!)}'),
        if (lastSentAt != null && lastReceivedAt != null)
          const SizedBox(width: 6),
        if (lastReceivedAt != null) _Chip(text: '💕 Nhận: ${fmt(lastReceivedAt!)}'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF4C0D1), width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF993556),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
