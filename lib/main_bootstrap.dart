import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'models/topic.dart';
import 'services/notification_service.dart';
import 'services/schedule_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TopicAdapter());

  // Load schedule settings on startup
  final schedule = ScheduleService();
  await schedule.load();

  final notifications = NotificationService();
  await notifications.init();

  runApp(MyApp(notifications: notifications, schedule: schedule));
}
