import 'dart:async';
import 'package:flutter/material.dart';

class AlarmOverlay extends StatefulWidget {
  final String partnerName;
  final String partnerInitial;
  final String signalType;
  final VoidCallback onSendBack;
  final VoidCallback onDismiss;

  const AlarmOverlay({
    super.key,
    required this.partnerName,
    required this.partnerInitial,
    required this.signalType,
    required this.onSendBack,
    required this.onDismiss,
  });

  @override
  State<AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends State<AlarmOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;
  Timer? _timer;
  int _countdown = 5;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );

    _scaleCtrl.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  Color get _pastelBg => switch (widget.signalType) {
        'miss' => const Color(0xFFF3E8FF),
        'care' => const Color(0xFFFFF7ED),
        _ => const Color(0xFFFFF0F5),
      };

  Color get _signalColor => switch (widget.signalType) {
        'miss' => const Color(0xFFC084FC),
        'care' => const Color(0xFFFB923C),
        _ => const Color(0xFFEC4899),
      };

  String get _label => switch (widget.signalType) {
        'miss' => 'Nhớ lắm',
        'care' => 'Quan tâm',
        _ => 'Yêu lắm',
      };

  String get _message => switch (widget.signalType) {
        'miss' => 'nhớ em lắm...',
        'care' => 'đang nghĩ đến em',
        _ => 'yêu em lắm...',
      };

  void _handleDismiss() {
    _timer?.cancel();
    widget.onDismiss();
  }

  void _handleSendBack() {
    _timer?.cancel();
    widget.onSendBack();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFFFFF0F5).withValues(alpha: 0.95),
        child: Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          shadowColor: const Color(0xFFEC4899).withValues(alpha: 0.3),
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
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
                    widget.partnerInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  widget.partnerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1a2e),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Subtitle
                const Text(
                  'vừa gửi cho bạn',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Icon Container
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pastelBg,
                  ),
                  alignment: Alignment.center,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Icon(
                      Icons.favorite,
                      color: _signalColor,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Label
                Text(
                  _label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _signalColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Message
                Text(
                  _message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleDismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFBE185D),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          side: const BorderSide(color: Color(0xFFFBCFE8)),
                        ),
                        child: const Text('Đóng'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSendBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '💕 Gửi lại',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Countdown Text
                Text(
                  'Tự đóng sau ${_countdown}s',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
