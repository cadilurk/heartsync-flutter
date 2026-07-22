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
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  Timer? _timer;
  int _countdown = 30;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );
    _scaleCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
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
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Signal colors & labels ───────────────────────────────────────────────────
  Color get _accentColor => switch (widget.signalType) {
        'miss' => const Color(0xFFC084FC),
        'care' => const Color(0xFFFB923C),
        _ => const Color(0xFFFF4B72),
      };

  Color get _pastelBg => switch (widget.signalType) {
        'miss' => const Color(0xFFF3E8FF),
        'care' => const Color(0xFFFFF7ED),
        _ => const Color(0xFFFFEEF3),
      };

  String get _emoji => switch (widget.signalType) {
        'miss' => '🥺',
        'care' => '🤗',
        _ => '💕',
      };

  String get _label => switch (widget.signalType) {
        'miss' => 'Nhớ em lắm!',
        'care' => 'Đang nghĩ đến em',
        _ => 'Yêu em lắm!',
      };

  String get _message => switch (widget.signalType) {
        'miss' => 'Đối phương đang rất nhớ bạn... 🥺',
        'care' => 'Một cái ôm ấm áp gửi từ phương xa 🤗',
        _ => 'Trái tim ai đó đang đập rộn ràng vì bạn 💕',
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

  double get _progress => _countdown / 30.0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 320,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFFFD4E0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Avatar with Pulsing Countdown Ring ─────────────────
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Pulsing Glow Circle
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        // Progress ring
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 3.5,
                            backgroundColor: const Color(0xFFF3E8EC),
                            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                          ),
                        ),
                        // Avatar Circle
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                _accentColor,
                                const Color(0xFFFF8DA1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.partnerInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Partner Name & Tagline ──────────────────────────────
                    Text(
                      widget.partnerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF231B1E),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _pastelBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Vừa rung chuông gửi tín hiệu yêu thương 🔔',
                        style: TextStyle(
                          fontSize: 12,
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Big Signal Heart Card ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _pastelBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _emoji,
                            style: const TextStyle(fontSize: 44),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _label,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF706066),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Action Buttons ─────────────────────────────────────
                    Row(
                      children: [
                        // Dismiss Button
                        Expanded(
                          flex: 4,
                          child: OutlinedButton(
                            onPressed: _handleDismiss,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF706066),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              side: const BorderSide(
                                color: Color(0xFFE0D5DA),
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              'Tắt',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Send Back Button
                        Expanded(
                          flex: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  _accentColor,
                                  const Color(0xFFFF537B),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _handleSendBack,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Gửi lại 💕',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Countdown Timer Text ───────────────────────────────
                    Text(
                      'Tự động đóng sau ${_countdown}s',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA09498),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


