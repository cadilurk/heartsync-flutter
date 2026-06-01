import 'dart:typed_data';
import 'dart:ui' as ui;

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

    final vibrationPattern = Int64List.fromList([0, 0, 300, 150, 300]);

    final channel = AndroidNotificationChannel(
      'heart_alarm',
      'Heart Alarm',
      description: 'Tín hiệu từ người yêu',
      importance: Importance.max,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      ledColor: const Color(0xFFEC4899),
      enableLights: true,
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
    final (emoji, message, subLabel) = switch (signalType) {
      'miss' => ('🥺', 'nhớ bạn lắm...', 'Nhớ lắm'),
      'care' => ('🤗', 'đang nghĩ đến bạn', 'Nghĩ đến em'),
      _ => ('💕', 'yêu bạn lắm...', 'Yêu lắm'),
    };

    final avatarBytes = await _buildAvatarBytes(partnerName);
    final avatarBitmap = ByteArrayAndroidBitmap(avatarBytes);
    final avatarIcon = ByteArrayAndroidIcon(avatarBytes);

    final sender = Person(
      name: partnerName,
      icon: avatarIcon,
      important: true,
    );

    final msgStyle = MessagingStyleInformation(
      sender,
      conversationTitle: 'HeartSync',
      groupConversation: false,
      messages: [
        Message('$emoji  $message', DateTime.now(), sender),
      ],
    );

    final androidDetails = AndroidNotificationDetails(
      'heart_alarm',
      'Heart Alarm',
      channelDescription: 'Tín hiệu từ người yêu',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFFEC4899),
      styleInformation: msgStyle,
      largeIcon: avatarBitmap,
      subText: subLabel,
      vibrationPattern: Int64List.fromList([0, 0, 300, 150, 300]),
      playSound: true,
      enableLights: true,
      ledColor: const Color(0xFFEC4899),
      ledOnMs: 400,
      ledOffMs: 400,
      ticker: '$partnerName $emoji',
      fullScreenIntent: false,
    );

    await _plugin.show(
      0,
      '$partnerName $emoji',
      message,
      NotificationDetails(android: androidDetails),
    );
  }

  // Tạo avatar PNG bytes hình tròn với chữ cái đầu
  Future<Uint8List> _buildAvatarBytes(String name) async {
    const size = 128.0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '♥';

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Pink gradient circle
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFC084FC), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(0, 0, size, size));

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      bgPaint,
    );

    // Initial text centered
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 62,
        fontWeight: ui.FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFFFFFFFF)))
      ..addText(initial);

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: size));

    canvas.drawParagraph(
      paragraph,
      Offset(0, (size - paragraph.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return bytes!.buffer.asUint8List();
  }
}
