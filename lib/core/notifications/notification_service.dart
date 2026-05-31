import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    final vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

    final channel = AndroidNotificationChannel(
      'heart_alarm',
      'Heart Alarm',
      importance: Importance.high,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showAlarmNotification({
    required String partnerName,
    required String signalType,
  }) async {
    final (emoji, body) = switch (signalType) {
      'miss' => ('🥺', 'nhớ em lắm...'),
      'care' => ('🤗', 'đang nghĩ đến em'),
      _ => ('💕', 'yêu em lắm...'),
    };

    final androidDetails = AndroidNotificationDetails(
      'heart_alarm',
      'Heart Alarm',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFFEC4899),
      styleInformation: BigTextStyleInformation(body),
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );

    await _plugin.show(
      0,
      '$partnerName gửi signal $emoji',
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}
