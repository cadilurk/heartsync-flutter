// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/network/socket_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/overlay/overlay_manager.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/signal.dart';
import '../services/signal_service.dart';

enum SignalType { miss, care, love }

class AlarmProvider extends ChangeNotifier {
  final SocketService _socketService;
  final AuthProvider _authProvider;
  final SignalService _signalService;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime? _lastSentAt;
  DateTime? _lastReceivedAt;
  bool _isReceiving = false;
  SignalType _selectedSignalType = SignalType.love;
  SignalType? _lastSentSignalType;
  SignalType? _lastReceivedSignalType;
  int unreadCount = 0;

  DateTime? get lastSentAt => _lastSentAt;
  DateTime? get lastReceivedAt => _lastReceivedAt;
  bool get isReceiving => _isReceiving;
  bool get isConnected => _socketService.isConnected;
  SignalType get selectedSignalType => _selectedSignalType;
  SignalType? get lastSentSignalType => _lastSentSignalType;
  SignalType? get lastReceivedSignalType => _lastReceivedSignalType;

  void Function()? onPartnerOfflineCallback;

  final List<Signal> _signalQueue = [];
  bool _isShowingOverlay = false;

  AlarmProvider({
    required SocketService socketService,
    required AuthProvider authProvider,
    required SignalService signalService,
  })  : _socketService = socketService,
        _authProvider = authProvider,
        _signalService = signalService {
    _socketService.onAlarmReceived = _handleAlarmReceived;
    _socketService.onPartnerOffline = _handlePartnerOffline;
    
    // Register FCM listeners
    FcmService.onForegroundMessage = handleFcmMessage;
    FcmService.onMessageOpened = handleFcmMessage;
  }

  void handleFcmMessage(RemoteMessage msg) {
    final signalId = msg.data['signalId'] as String?;
    final fromUserId = msg.data['fromUserId'] as String? ?? '';
    final signalType = msg.data['signalType'] as String?;
    _handleAlarmReceived(signalId, fromUserId, DateTime.now(), signalType);
  }

  void selectSignal(SignalType type) {
    if (_selectedSignalType == type) return;
    _selectedSignalType = type;
    notifyListeners();
  }

  bool get isCooldownActive {
    if (_lastSentAt == null) return false;
    return DateTime.now().difference(_lastSentAt!).inSeconds < 3;
  }

  Future<void> sendAlarmWithType(SignalType type) async {
    if (isCooldownActive) return;
    try {
      final now = DateTime.now();
      _lastSentAt = now;
      _lastSentSignalType = type;
      notifyListeners();

      await _signalService.sendSignal(type);
    } catch (e) {
      debugPrint('Error sending signal: $e');
    }
  }

  Future<void> sendAlarm() async {
    await sendAlarmWithType(_selectedSignalType);
  }

  void startShakeDetection() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > 10) {
        sendAlarm();
      }
    });
  }

  void stopShakeDetection() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  Future<void> fetchUnreadSignals() async {
    try {
      final unreads = await _signalService.getUnread();
      if (unreads.isEmpty) return;

      for (final signal in unreads) {
        _showOverlayForSignal(signal);
        await _signalService.markRead(signal.id);
      }
      unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching unread signals: $e');
    }
  }

  void _showOverlayForSignal(Signal signal) {
    _signalQueue.add(signal);
    if (!_isShowingOverlay) {
      _showNextSignalInQueue();
    }
  }

  void _showNextSignalInQueue() {
    if (_signalQueue.isEmpty) {
      _isShowingOverlay = false;
      return;
    }

    _isShowingOverlay = true;
    final signal = _signalQueue.removeAt(0);

    final partnerName = signal.fromDisplayName ?? _partnerName(_authProvider.session.partner?.email);
    final partnerInitial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';

    OverlayManager().showAlarmOverlay(
      partnerName: partnerName,
      partnerInitial: partnerInitial,
      signalType: signal.signalType.name,
      onSendBack: () => sendAlarmWithType(signal.signalType),
      onDismissCallback: () {
        _showNextSignalInQueue();
      },
    );
  }

  void _handleAlarmReceived(
    String? signalId,
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
    final type = SignalType.values.firstWhere(
      (e) => e.name == signalType,
      orElse: () => SignalType.love,
    );
    _lastReceivedSignalType = type;
    notifyListeners();

    // 3. Foreground -> overlay, background -> notification
    final isForegrounded =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (isForegrounded) {
      final partnerName = _partnerName(_authProvider.session.partner?.email);
      final partnerInitial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';

      OverlayManager().showAlarmOverlay(
        partnerName: partnerName,
        partnerInitial: partnerInitial,
        signalType: type.name,
        onSendBack: () => sendAlarmWithType(type),
        onDismissCallback: () {
          _showNextSignalInQueue();
        },
      );

      if (signalId != null) {
        try {
          await _signalService.markRead(signalId);
        } catch (e) {
          debugPrint('Error marking signal as read: $e');
        }
      }
    } else {
      final partner = _authProvider.session.partner;
      final partnerName = _partnerName(partner?.email);
      await NotificationService().showAlarmNotification(
        partnerName: partnerName,
        signalType: type.name,
      );

      unreadCount++;
      notifyListeners();
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

