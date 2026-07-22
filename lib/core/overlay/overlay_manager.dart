import 'package:flutter/material.dart';

import '../../features/alarm/widgets/alarm_overlay.dart';

class OverlayManager {
  OverlayManager._();
  static final OverlayManager _instance = OverlayManager._();
  factory OverlayManager() => _instance;

  OverlayEntry? _entry;
  BuildContext? _context;

  void init(BuildContext context) {
    _context = context;
  }

  void showAlarmOverlay({
    required String partnerName,
    required String partnerInitial,
    String? partnerAvatarUrl,
    required String signalType,
    required VoidCallback onSendBack,
    VoidCallback? onDismissCallback,
  }) {
    if (_entry != null || _context == null) return;
    if (!(_context!.mounted)) return;

    try {
      _entry = OverlayEntry(
        builder: (_) => AlarmOverlay(
          partnerName: partnerName,
          partnerInitial: partnerInitial,
          partnerAvatarUrl: partnerAvatarUrl,
          signalType: signalType,
          onSendBack: onSendBack,
          onDismiss: () {
            dismiss();
            onDismissCallback?.call();
          },
        ),
      );

      Overlay.of(_context!).insert(_entry!);
    } catch (e) {
      debugPrint('OverlayManager: failed to show overlay — $e');
      _entry = null;
    }
  }

  void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}
