// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

import '../../../core/network/socket_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/overlay/overlay_manager.dart';
import '../../auth/providers/auth_provider.dart';

enum SignalType { miss, care, love }

class AlarmProvider extends ChangeNotifier {
  final SocketService _socketService;
  final AuthProvider _authProvider;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime? _lastSentAt;
  DateTime? _lastReceivedAt;
  bool _isReceiving = false;
  SignalType _selectedSignalType = SignalType.love;
  SignalType? _lastSentSignalType;
  SignalType? _lastReceivedSignalType;

  DateTime? get lastSentAt => _lastSentAt;
  DateTime? get lastReceivedAt => _lastReceivedAt;
  bool get isReceiving => _isReceiving;
  bool get isConnected => _socketService.isConnected;
  SignalType get selectedSignalType => _selectedSignalType;
  SignalType? get lastSentSignalType => _lastSentSignalType;
  SignalType? get lastReceivedSignalType => _lastReceivedSignalType;

  void Function()? onPartnerOfflineCallback;

  AlarmProvider({
    required SocketService socketService,
    required AuthProvider authProvider,
  })  : _socketService = socketService,
        _authProvider = authProvider {
    _socketService.onAlarmReceived = _handleAlarmReceived;
    _socketService.onPartnerOffline = _handlePartnerOffline;
  }

  void selectSignal(SignalType type) {
    if (_selectedSignalType == type) return;
    _selectedSignalType = type;
    notifyListeners();
  }

  void startShakeDetection() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > 25) {
        final now = DateTime.now();
        final cooldownPassed = _lastSentAt == null ||
            now.difference(_lastSentAt!).inSeconds >= 3;
        if (!cooldownPassed) return;

        final partnerId = _authProvider.session.partner?.id;
        if (partnerId == null) return;

        _socketService.sendAlarm(partnerId, _selectedSignalType.name);
        _lastSentAt = now;
        _lastSentSignalType = _selectedSignalType;
        notifyListeners();
      }
    });
  }

  void stopShakeDetection() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  // Gửi alarm ngay (dùng cho nút "Gửi lại" trong overlay)
  void sendAlarmNow() {
    final partnerId = _authProvider.session.partner?.id;
    if (partnerId == null) return;
    final now = DateTime.now();
    final cooldownPassed = _lastSentAt == null ||
        now.difference(_lastSentAt!).inSeconds >= 3;
    if (!cooldownPassed) return;
    _socketService.sendAlarm(partnerId, _selectedSignalType.name);
    _lastSentAt = now;
    _lastSentSignalType = _selectedSignalType;
    notifyListeners();
  }

  void _handleAlarmReceived(
    String fromUserId,
    DateTime timestamp,
    String? signalType,
  ) async {
    // 1. Vibration
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(pattern: [0, 500, 200, 500]);
    }

    // 2. Update state
    _lastReceivedAt = timestamp;
    _isReceiving = true;
    _lastReceivedSignalType = SignalType.values
            .where((e) => e.name == signalType)
            .firstOrNull ??
        SignalType.love;
    notifyListeners();

    // 3. Foreground → overlay, background → push notification
    final partner = _authProvider.session.partner;
    final partnerName = _partnerName(partner?.email);
    final resolvedSignal = signalType ?? 'love';

    final isForegrounded =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (isForegrounded) {
      OverlayManager().showAlarmOverlay(
        partnerName: partnerName,
        partnerInitial: partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?',
        signalType: resolvedSignal,
        onSendBack: sendAlarmNow,
      );
    } else {
      await NotificationService().showAlarmNotification(
        partnerName: partnerName,
        signalType: resolvedSignal,
      );
    }

    // 4. Reset receiving state after 3s
    await Future.delayed(const Duration(seconds: 3));
    _isReceiving = false;
    notifyListeners();
  }

  String _partnerName(String? email) {
    if (email == null || email.isEmpty) return 'Partner';
    return email.split('@').first;
  }

  void _handlePartnerOffline() {
    onPartnerOfflineCallback?.call();
  }

  @override
  void dispose() {
    stopShakeDetection();
    _socketService.onAlarmReceived = null;
    _socketService.onPartnerOffline = null;
    super.dispose();
  }
}
