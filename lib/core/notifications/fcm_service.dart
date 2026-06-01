import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background FCM payload handler. No UI code can run here.
  debugPrint('Handling a background message: ${message.messageId}');
}

class FcmService {
  FcmService._();
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  ApiClient? _apiClient;
  String? _lastToken;
  bool _initialized = false;

  static void Function(RemoteMessage)? onForegroundMessage;
  static void Function(RemoteMessage)? onMessageOpened;

  Future<void> initialize(ApiClient apiClient) async {
    _apiClient = apiClient;
    if (_initialized) return;
    _initialized = true;

    // 1. Request notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted FCM permission');
    }

    // 2. Get registration token
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenOnServer(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // 3. Listen to token refresh events
    _messaging.onTokenRefresh.listen((token) async {
      await _updateTokenOnServer(token);
    });

    // 4. Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground message received: ${message.messageId}');
      onForegroundMessage?.call(message);
    });

    // 5. Handle tapping notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened app: ${message.messageId}');
      onMessageOpened?.call(message);
    });

    // 6. Check if the app was opened from a terminated state via a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM initial message received: ${initialMessage.messageId}');
      Future.delayed(const Duration(milliseconds: 800), () {
        onMessageOpened?.call(initialMessage);
      });
    }
  }

  Future<void> unregisterToken() async {
    if (_lastToken != null && _apiClient != null) {
      try {
        await _apiClient!.delete<bool>(
          '/users/me/fcm-token',
          {'token': _lastToken},
          (json) => json == true,
        );
        _lastToken = null;
      } catch (e) {
        debugPrint('Error deleting FCM token from server: $e');
      }
    }
    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('Error deleting FCM token locally: $e');
    }
  }

  Future<void> _updateTokenOnServer(String token) async {
    _lastToken = token;
    if (_apiClient == null) return;
    try {
      await _apiClient!.put<bool>(
        '/users/me/fcm-token',
        {'token': token},
        (json) => json == true,
      );
      debugPrint('FCM token uploaded to server: $token');
    } catch (e) {
      debugPrint('Error uploading FCM token: $e');
    }
  }
}
