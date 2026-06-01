import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  ApiConstants._();

  static const baseUrl = String.fromEnvironment(
    'HEART_SYNC_API_BASE_URL',
    defaultValue: 'http://localhost:5291',
  );

  static bool get useMockApi => baseUrl.startsWith('mock://');

  // Runtime URL: web → localhost, emulator/simulator → auto config, real device → IP cấu hình
  static String resolveBaseUrl() {
    if (kIsWeb) {
      // Trên Web: Luôn chuyển các IP local về localhost
      return baseUrl
          .replaceFirst('http://10.0.2.2', 'http://localhost')
          .replaceFirst('http://127.0.0.1', 'http://localhost')
          .replaceAll(RegExp(r'http://10\.\d+\.\d+\.\d+'), 'http://localhost')
          .replaceAll(RegExp(r'http://192\.168\.\d+\.\d+'), 'http://localhost');
    }

    try {
      // Trên Android Emulator: tự động chuyển localhost thành 10.0.2.2
      if (Platform.isAndroid) {
        return baseUrl
            .replaceFirst('http://localhost', 'http://10.0.2.2')
            .replaceFirst('http://127.0.0.1', 'http://10.0.2.2');
      }
    } catch (_) {
      // Dự phòng nếu có lỗi khi gọi Platform trên môi trường không hỗ trợ
    }

    return baseUrl;
  }

  static String get socketUrl => resolveBaseUrl().replaceFirst('http', 'ws');
}
