import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _connected = false;

  bool get isConnected => _connected;

  void Function(String? signalId, String fromUserId, DateTime timestamp, String? signalType)? onAlarmReceived;
  void Function()? onPartnerOffline;
  void Function()? onReconnected;

  void connect(String token) {
    if (_socket != null) return;

    final url = _resolveUrl();

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      notifyListeners();
    });

    _socket!.on('reconnect', (_) {
      onReconnected?.call();
    });

    _socket!.on('alarm:receive', (data) {
      if (data is Map) {
        final signalId = data['signalId'] as String?;
        final fromUserId = data['fromUserId'] as String? ?? '';
        final ts = data['timestamp'] as String?;
        final timestamp =
            ts != null ? DateTime.tryParse(ts) ?? DateTime.now() : DateTime.now();
        final signalType = data['signalType'] as String?;
        onAlarmReceived?.call(signalId, fromUserId, timestamp, signalType);
      }
    });

    _socket!.on('alarm:partner_offline', (_) {
      onPartnerOffline?.call();
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connected = false;
    notifyListeners();
  }

  void sendAlarm(String partnerId, String signalType) {
    _socket?.emit('alarm:send', {'partnerId': partnerId, 'signalType': signalType});
  }

  String _resolveUrl() => ApiConstants.resolveBaseUrl();

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
