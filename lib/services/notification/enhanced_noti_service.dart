import 'dart:convert';

import 'package:chessgame/services/notification/noti_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class EnhancedNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final NotiService _localNotificationService = NotiService();
  static Function(Map<String, dynamic>)? _onChatNotificationTap;

  // Store user tokens instead of topic subscriptions
  static final Map<String, String> _userTokens = {}; // user_id -> device_token
  static final Map<String, List<String>> _locationTokens =
      {}; // location -> list of tokens
  static final Map<String, List<String>> _metadataTokens =
      {}; // metadata_key_value -> list of tokens

  static String? _currentUserId;
  static String? _currentUserToken;

  static Future<void> initialize({
    Function(Map<String, dynamic>)? onChatNotificationTap,
    String? userId,
  }) async {
    _onChatNotificationTap = onChatNotificationTap;
    _currentUserId = userId;

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
      // Get and store the current device token
      _currentUserToken = await getToken();
      if (_currentUserToken != null && userId != null) {
        _userTokens[userId] = _currentUserToken!;
        print('Stored token for user: $userId');
      }
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

  Future<String> getDeviceToken() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await _firebaseMessaging.getToken();
    print('Token => $token');
    return token!;
  }

  // Store user token with metadata
  static Future<void> registerUserToken({
    required String userId,
    required String deviceToken,
    String? location,
    Map<String, String>? metadata,
  }) async {
    _userTokens[userId] = deviceToken;

    if (location != null) {
      String cleanLocation = location.toLowerCase().replaceAll(' ', '_');
      if (!_locationTokens.containsKey(cleanLocation)) {
        _locationTokens[cleanLocation] = [];
      }
      _locationTokens[cleanLocation]!.add(deviceToken);
    }

    if (metadata != null) {
      metadata.forEach((key, value) {
        String metadataKey =
            '${key}_${value.toLowerCase().replaceAll(' ', '_')}';
        if (!_metadataTokens.containsKey(metadataKey)) {
          _metadataTokens[metadataKey] = [];
        }
        _metadataTokens[metadataKey]!.add(deviceToken);
      });
    }

    print('Registered token for user: $userId');
    print('Total users registered: ${_userTokens.length}');
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

  // Send to specific device token
  static Future<bool> sendNotificationToDevice({
    required String deviceToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String serverKey,
  }) async {
    try {
      print('Sending to device token: ${deviceToken.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': deviceToken, // Direct device token
          'notification': {'title': title, 'body': body, 'sound': 'default'},
          'data': data,
          'priority': 'high',
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'chess_game_channel',
              'sound': 'default',
            },
          },
        }),
      );

      print('FCM Response: ${response.statusCode}');
      print('FCM Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Notification sent successfully to device');
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

  // Send to specific user by ID (using stored token)
  static Future<bool> sendNotificationToUserById({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String serverKey,
  }) async {
    try {
      if (!_userTokens.containsKey(targetUserId)) {
        print('❌ No device token found for user: $targetUserId');
        return false;
      }

      String deviceToken = _userTokens[targetUserId]!;
      return await sendNotificationToDevice(
        deviceToken: deviceToken,
        title: title,
        body: body,
        data: data,
        serverKey: serverKey,
      );
    } catch (e) {
      print('Error sending to user: $e');
      return false;
    }
  }

  // Send to multiple devices (for location-based targeting)
  static Future<bool> sendNotificationToMultipleDevices({
    required List<String> deviceTokens,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String serverKey,
  }) async {
    try {
      if (deviceTokens.isEmpty) {
        print('❌ No device tokens provided');
        return false;
      }

      bool allSuccess = true;

      for (String token in deviceTokens) {
        bool success = await sendNotificationToDevice(
          deviceToken: token,
          title: title,
          body: body,
          data: data,
          serverKey: serverKey,
        );

        if (!success) {
          allSuccess = false;
          print('Failed to send to token: ${token.substring(0, 10)}...');
        }

        // Add small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return allSuccess;
    } catch (e) {
      print('Error sending to multiple devices: $e');
      return false;
    }
  }

  // Location-based notification using stored tokens
  static Future<bool> sendNotificationToLocation({
    required String targetLocation,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String serverKey,
  }) async {
    try {
      String cleanLocation = targetLocation.toLowerCase().replaceAll(' ', '_');

      if (!_locationTokens.containsKey(cleanLocation) ||
          _locationTokens[cleanLocation]!.isEmpty) {
        print('❌ No devices registered for location: $targetLocation');
        return false;
      }

      List<String> tokens = _locationTokens[cleanLocation]!;
      print('Sending to ${tokens.length} devices in location: $targetLocation');

      return await sendNotificationToMultipleDevices(
        deviceTokens: tokens,
        title: title,
        body: body,
        data: data,
        serverKey: serverKey,
      );
    } catch (e) {
      print('Error sending location-based notification: $e');
      return false;
    }
  }

  // Chat notification methods
  static Future<bool> sendChatNotification({
    required String recipientToken,
    required String senderName,
    required String message,
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String serverKey,
  }) async {
    return await sendNotificationToDevice(
      deviceToken: recipientToken,
      title: senderName,
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

  static Future<bool> sendTargetChatNotification({
    required String targetUserId,
    required String senderName,
    required String message,
    required String chatRoomId,
    required String senderId,
    required String serverKey,
  }) async {
    return await sendNotificationToUserById(
      targetUserId: targetUserId,
      title: senderName,
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      data: {
        'type': 'chat_message',
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': targetUserId,
        'message': message,
      },
      serverKey: serverKey,
    );
  }

  // User management methods
  static Future<void> updateUserTargeting({
    String? userId,
    String? deviceToken,
    String? location,
    Map<String, String>? metadata,
  }) async {
    try {
      if (userId != null && deviceToken != null) {
        await registerUserToken(
          userId: userId,
          deviceToken: deviceToken,
          location: location,
          metadata: metadata,
        );
      }
      print('User targeting updated successfully');
    } catch (e) {
      print('Update user targeting error: $e');
    }
  }

  static Map<String, dynamic> getUserTargetingInfo() {
    return {
      'currentUserId': _currentUserId ?? 'Not set',
      'currentUserToken': _currentUserToken != null
          ? '${_currentUserToken!.substring(0, 10)}...'
          : 'Not set',
      'registeredUsers': _userTokens.length,
      'registeredLocations': _locationTokens.length,
      'registeredMetadata': _metadataTokens.length,
    };
  }

  // Local notification methods
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
      payload: '/game_page',
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotificationService.cancelAllNotifications();
  }

  static Future<void> testNotification() async {
    await _localNotificationService.showNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Enhanced Service',
      payload: jsonEncode({'type': 'test', 'message': 'Test payload'}),
    );
  }

  // Test method with device token
  static Future<void> testTargetedNotification({
    required String serverKey,
  }) async {
    if (_currentUserToken != null) {
      await sendNotificationToDevice(
        deviceToken: _currentUserToken!,
        title: 'Targeted Test',
        body: 'This notification was sent to your device!',
        data: {'type': 'targeted_test', 'timestamp': DateTime.now().toString()},
        serverKey: serverKey,
      );
    }
  }
}
