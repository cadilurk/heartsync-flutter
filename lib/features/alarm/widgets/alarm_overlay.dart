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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) { timer.cancel(); widget.onDismiss(); }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  // ── Signal colors ────────────────────────────────────────────────────────────
  Color get _accentColor => switch (widget.signalType) {
        'miss' => const Color(0xFFA855F7),
        'care' => const Color(0xFFF97316),
        _ => const Color(0xFFEC4899),
      };

  Color get _pastelBg => switch (widget.signalType) {
        'miss' => const Color(0xFFF5F0FF),
        'care' => const Color(0xFFFFF4ED),
        _ => const Color(0xFFFFF0F7),
      };

  String get _label => switch (widget.signalType) {
        'miss' => 'Nhớ lắm',
        'care' => 'Quan tâm',
        _ => 'Yêu lắm',
      };

  String get _message => switch (widget.signalType) {
        'miss' => 'nhớ em lắm... 🥺',
        'care' => 'đang nghĩ đến em 🤗',
        _ => 'yêu em lắm... 💕',
      };

  void _handleDismiss() { _timer?.cancel(); widget.onDismiss(); }
  void _handleSendBack() { _timer?.cancel(); widget.onSendBack(); widget.onDismiss(); }

  // ── Progress arc for countdown ───────────────────────────────────────────────
  double get _progress => _countdown / 30.0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Container(
          // Gradient background
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFCE4EC).withValues(alpha: 0.96),
                const Color(0xFFF8BBD9).withValues(alpha: 0.98),
              ],
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.25),
                      blurRadius: 48,
                      spreadRadius: 4,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── Avatar với countdown ring ────────────────────────────
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress ring
                        SizedBox(
                          width: 84,
                          height: 84,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 3,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        // Avatar circle
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFC084FC),
                                _accentColor,
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
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Tên partner ──────────────────────────────────────────
                    Text(
                      widget.partnerName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a1a2e),
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    Text(
                      'vừa gửi cho bạn',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Heart icon ───────────────────────────────────────────
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _pastelBg,
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: _accentColor,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Label & message ──────────────────────────────────────
                    Text(
                      _label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      _message,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Buttons ──────────────────────────────────────────────
                    Row(
                      children: [
                        // Đóng  (flex 4)
                        Expanded(
                          flex: 4,
                          child: OutlinedButton(
                            onPressed: _handleDismiss,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFBE185D),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              side: BorderSide(
                                color: _accentColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Đóng',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Gửi lại  (flex 6)
                        Expanded(
                          flex: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFF472B6),
                                  _accentColor,
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
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                '💕 Gửi lại',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Countdown text ───────────────────────────────────────
                    Text(
                      'Tự đóng sau ${_countdown}s',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.3,
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
