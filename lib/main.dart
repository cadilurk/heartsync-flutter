import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  runApp(const HeartSyncApp());
  
  // Init sau khi app đã chạy để không block splash screen
  if (!kIsWeb && Platform.isAndroid) {
    NotificationService().initialize();
    Permission.notification.request();
  }
}
