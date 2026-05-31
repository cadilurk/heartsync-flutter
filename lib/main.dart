import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await Permission.notification.request();
  runApp(const HeartSyncApp());
}
