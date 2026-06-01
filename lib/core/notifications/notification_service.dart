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
    final (emoji, title, body) = switch (signalType) {
      'miss' => ('🥺', '$partnerName nhớ bạn lắm 🥺', 'nhớ em lắm...'),
      'care' => ('🤗', '$partnerName đang nghĩ đến bạn 🤗', 'đang nghĩ đến em'),
      _ => ('💕', '$partnerName yêu bạn lắm 💕', 'yêu em lắm...'),
    };

    final androidDetails = AndroidNotificationDetails(
      'heart_alarm',
      'Heart Alarm',
      channelDescription: 'Thông báo tín hiệu từ người yêu',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFFEC4899),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'HeartSync',
      ),
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      playSound: true,
      enableLights: true,
      ledColor: const Color(0xFFEC4899),
      ledOnMs: 500,
      ledOffMs: 500,
      ticker: '$partnerName $emoji',
    );

    await _plugin.show(
      0,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}
