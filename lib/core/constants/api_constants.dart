import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  ApiConstants._();

  static const baseUrl = String.fromEnvironment(
    'HEART_SYNC_API_BASE_URL',
    defaultValue: 'http://10.12.81.150:5291',
  );

  static bool get useMockApi => baseUrl.startsWith('mock://');

  static String resolveBaseUrl() {
    // ngrok / https → giữ nguyên, không transform
    if (baseUrl.contains('ngrok') || baseUrl.startsWith('https://')) {
      return baseUrl;
    }

    if (kIsWeb) {
      return baseUrl
          .replaceAll(RegExp(r'http://\d+\.\d+\.\d+\.\d+'), 'http://localhost');
    }

    try {
      if (Platform.isAndroid) {
        return baseUrl
            .replaceFirst('http://localhost', 'http://10.0.2.2')
            .replaceFirst('http://127.0.0.1', 'http://10.0.2.2');
      }
    } catch (_) {}

    return baseUrl;
  }

  static String get socketUrl => resolveBaseUrl().replaceFirst('http', 'ws');
}
