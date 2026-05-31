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
    required String signalType,
    required VoidCallback onSendBack,
  }) {
    if (_entry != null || _context == null) return;

    _entry = OverlayEntry(
      builder: (_) => AlarmOverlay(
        partnerName: partnerName,
        partnerInitial: partnerInitial,
        signalType: signalType,
        onSendBack: onSendBack,
        onDismiss: dismiss,
      ),
    );

    Overlay.of(_context!).insert(_entry!);
  }

  void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}
