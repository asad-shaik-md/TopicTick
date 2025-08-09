import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );

    const settings = InitializationSettings(iOS: darwin, macOS: darwin);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {},
    );

    // Explicitly request permissions on macOS/iOS
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    final macPlugin = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await macPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Ensure the time is in the future; if not, fire shortly.
    var tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzDate.isAfter(now)) {
      tzDate = now.add(const Duration(seconds: 5));
    }

    const details = NotificationDetails(
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: null,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
