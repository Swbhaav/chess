import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotiService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  //Callback for notification taps
  Function(String)? onNotificationTap;

  Future<void> init({Function(String)? onNotificationTap}) async {
    try {
      tz.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (onNotificationTap != null) {
            onNotificationTap(response.payload ?? '');
          }
        },
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String payload = '/video_page',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chess_game_channel',
      'Chess Game Notifications',
      channelDescription: 'Notifications for Chess Game',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        0,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      print('Show notification error: $e');
    }
  }

  Future<void> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String payload = '/video_page',
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'chess_game_channel',
      'Chess Game Notifications',
      channelDescription: 'Notifications for Chess Game',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      print('Notification scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      print('Schedule notification error: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      print('All notifications canceled');
    } catch (e) {
      print('Cancel notifications error: $e');
    }
  }
}
