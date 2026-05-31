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
  late final AnimationController _emojiCtrl;
  late final Animation<double> _emojiScale;
  Timer? _timer;
  int _countdown = 4;

  @override
  void initState() {
    super.initState();

    _emojiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _emojiScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emojiCtrl, curve: Curves.elasticOut),
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
    _emojiCtrl.dispose();
    super.dispose();
  }

  String get _emoji => switch (widget.signalType) {
        'miss' => '🥺',
        'care' => '🤗',
        _ => '💕',
      };

  String get _message => switch (widget.signalType) {
        'miss' => 'nhớ em lắm...',
        'care' => 'đang nghĩ đến em',
        _ => 'yêu em lắm...',
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF0F5).withValues(alpha: 0.96),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A. Emoji animated
              ScaleTransition(
                scale: _emojiScale,
                child: Text(
                  _emoji,
                  style: const TextStyle(fontSize: 72),
                ),
              ),

              // B. Partner name
              const SizedBox(height: 16),
              Text(
                widget.partnerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),

              // C. Message
              const SizedBox(height: 4),
              Text(
                _message,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9CA3AF),
                ),
              ),

              // D. Spacer
              const SizedBox(height: 24),

              // E. Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.onSendBack();
                      widget.onDismiss();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Gửi lại 💕',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: widget.onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBE185D),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: const BorderSide(color: Color(0xFFFBCFE8)),
                    ),
                    child: const Text('Đóng'),
                  ),
                ],
              ),

              // F. Countdown
              const SizedBox(height: 12),
              Text(
                'Tự đóng sau ${_countdown}s...',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
