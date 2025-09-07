import 'dart:convert';

import 'package:chessgame/services/notification/noti_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class EnhancedNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final NotiService _localNotificationService = NotiService();
  static Function(Map<String, dynamic>)? _onChatNotificationTap;

  static Future<void> initialize({
    Function(Map<String, dynamic>)? onChatNotificationTap,
  }) async {
    _onChatNotificationTap = onChatNotificationTap;

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('FCM User Granted permission');
    } else {
      print('FCM User declined or has not accepted permission');
    }
    await _localNotificationService.init(
      onNotificationTap: _handleLocalNotificationTap,
    );

    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.notification?.title}');

    await _localNotificationService.showNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new message',
      payload: jsonEncode(message.data),
    );
  }

  static void _handleLocalNotificationTap(String payload) {
    print('Local notification tapped with payload: $payload');

    try {
      if (payload.isNotEmpty && payload != '/video_page') {
        Map<String, dynamic> data = jsonDecode(payload);
        _handleChatNavigation(data);
      }
    } catch (e) {
      print('Error parsing notification payload: $e');
      _handleRegularNavigation(payload);
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('FCM Notification tapped: ${message.data}');
    _handleChatNavigation(message.data);
  }

  static void _handleChatNavigation(Map<String, dynamic> data) {
    if (_onChatNotificationTap != null) {
      _onChatNotificationTap!(data);
    } else {
      print('No chat notification handler registered');
    }
  }

  static void _handleRegularNavigation(String route) {
    print('Navigate to route: $route');
  }

  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<bool> sendNotificationToUser({
    required String recipientToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String serverKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': recipientToken,
          'notification': {'title': title, 'body': body, 'sound': 'default'},
          'data': data,
          'priority': 'high',
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'chess_game_channel', // Using your existing channel
              'sound': 'default',
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
        return true;
      } else {
        print('Failed to send notification: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  static Future<bool> sendChatNotification({
    required String recipientToken,
    required String senderName,
    required String message,
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String serverKey,
  }) async {
    return await sendNotificationToUser(
      recipientToken: recipientToken,
      title: senderId,
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      data: {
        'type': 'chat_message',
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'message': message,
      },
      serverKey: serverKey,
    );
  }

  static Future<void> showLocalChatNotification({
    required String senderName,
    required String message,
    required Map<String, dynamic> chatData,
  }) async {
    await _localNotificationService.showNotification(
      title: senderName,
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      payload: jsonEncode(chatData),
    );
  }

  // Subscribe to topic (for group notifications)
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Schedule reminder using your existing service
  static Future<void> scheduleGameReminder({
    int id = 1,
    required String opponentName,
    required int hour,
    required int minute,
  }) async {
    await _localNotificationService.scheduleNotification(
      id: id,
      title: 'Chess Game Reminder',
      body: 'You have a scheduled game with $opponentName',
      hour: hour,
      minute: minute,
      payload: '/game_page', // Or any route you want
    );
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotificationService.cancelAllNotifications();
  }

  // Test notification using your existing service
  static Future<void> testNotification() async {
    await _localNotificationService.showNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Enhanced Service',
      payload: jsonEncode({'type': 'test', 'message': 'Test payload'}),
    );
  }
}
