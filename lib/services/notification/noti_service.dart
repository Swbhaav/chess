import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotiService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Function(String)? onNotificationTap;

  Future<void> init({
    Function(String)? onNotificationTap,
    String? userId,
    String? userLocation,
    List<String>? userTopics,
  }) async {
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

  // Store current user ID
  Future<void> setCurrentUser(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
  }

  // Get current user ID
  Future<String?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id');
  }

  // Store notification preferences for users
  Future<void> setUserNotificationPreference(
    String userId,
    bool enabled,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_$userId', enabled);
  }

  // Check if user should receive notifications
  Future<bool> shouldNotifyUser(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_$userId') ?? true;
  }

  // Show notification to specific user only
  Future<void> showNotificationToUser({
    required String targetUserId,
    required String title,
    required String body,
    String payload = '/video_page',
  }) async {
    // Check if current user matches target user
    String? currentUserId = await getCurrentUser();
    if (currentUserId == null || currentUserId != targetUserId) {
      print(
        'Notification not sent: Current user ($currentUserId) does not match target user ($targetUserId)',
      );
      return;
    }

    // Check if user has enabled notifications
    bool shouldNotify = await shouldNotifyUser(targetUserId);
    if (!shouldNotify) {
      print(
        'Notification not sent: User $targetUserId has disabled notifications',
      );
      return;
    }

    await showNotification(title: title, body: body, payload: payload);
  }

  // Original show notification method (for internal use)
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
      print('Notification shown: $title');
    } catch (e) {
      print('Show notification error: $e');
    }
  }

  // Schedule notification for specific user
  Future<void> scheduleNotificationForUser({
    required String targetUserId,
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String payload = '/video_page',
  }) async {
    // Check if current user matches target user
    String? currentUserId = await getCurrentUser();
    if (currentUserId == null || currentUserId != targetUserId) {
      print(
        'Scheduled notification not set: Current user does not match target user',
      );
      return;
    }

    // Check if user has enabled notifications
    bool shouldNotify = await shouldNotifyUser(targetUserId);
    if (!shouldNotify) {
      print('Scheduled notification not set: User has disabled notifications');
      return;
    }

    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      payload: payload,
    );
  }

  // Original schedule notification method
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
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      print('Notification scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      print('Schedule notification error: $e');
    }
  }

  // Show notification based on user roles/groups
  Future<void> showNotificationToUserGroup({
    required List<String> targetUserIds,
    required String title,
    required String body,
    String payload = '/video_page',
  }) async {
    String? currentUserId = await getCurrentUser();
    if (currentUserId == null || !targetUserIds.contains(currentUserId)) {
      print('Notification not sent: Current user not in target group');
      return;
    }

    bool shouldNotify = await shouldNotifyUser(currentUserId);
    if (!shouldNotify) {
      print('Notification not sent: User has disabled notifications');
      return;
    }

    await showNotification(title: title, body: body, payload: payload);
  }

  // Chat notification for specific user
  Future<void> showChatNotificationToUser({
    required String targetUserId,
    required String senderName,
    required String message,
    required String chatRoomId,
    required String senderId,
  }) async {
    await showNotificationToUser(
      targetUserId: targetUserId,
      title: senderName,
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      payload:
          '{"type":"chat","chatRoomId":"$chatRoomId","senderId":"$senderId"}',
    );
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

// Usage Example
class NotificationManager {
  static final NotiService _notiService = NotiService();

  static Future<void> initialize(String currentUserId) async {
    await _notiService.init();
    await _notiService.setCurrentUser(currentUserId);
  }

  // Send notification to specific user
  static Future<void> notifyUser(
    String userId,
    String title,
    String message,
  ) async {
    await _notiService.showNotificationToUser(
      targetUserId: userId,
      title: title,
      body: message,
    );
  }

  // Send chat notification
  static Future<void> sendChatNotification({
    required String targetUserId,
    required String senderName,
    required String message,
    required String chatRoomId,
    required String senderId,
  }) async {
    await _notiService.showChatNotificationToUser(
      targetUserId: targetUserId,
      senderName: senderName,
      message: message,
      chatRoomId: chatRoomId,
      senderId: senderId,
    );
  }

  // Enable/disable notifications for current user
  static Future<void> setNotificationPreference(bool enabled) async {
    String? currentUserId = await _notiService.getCurrentUser();
    if (currentUserId != null) {
      await _notiService.setUserNotificationPreference(currentUserId, enabled);
    }
  }
}
