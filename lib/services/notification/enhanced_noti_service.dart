import 'dart:convert';

import 'package:chessgame/services/notification/noti_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class EnhancedNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final NotiService _localNotificationService = NotiService();
  static Function(Map<String, dynamic>)? _onChatNotificationTap;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? _currentUserId;
  static String? _currentUserToken;

  static const String userCollection = 'Users';
  static const String fcmTokensCollection = 'fcmToken';

  // Legacy in-memory storage (for backward compatibility)
  static final Map<String, String> _userTokens = {};
  static final Map<String, List<String>> _locationTokens = {};
  static final Map<String, List<String>> _metadataTokens = {};

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
        // Store token in both Firestore AND in-memory for immediate access
        await _storeTokenInFirestore(userId, _currentUserToken!);
        _userTokens[userId] = _currentUserToken!; // Add this line
        print('Stored token for user: $userId in Firestore and memory');
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

    // Handle token refresh
    await handleTokenRefresh();

    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Store token in Firestore
  static Future<void> _storeTokenInFirestore(
    String userId,
    String deviceToken,
  ) async {
    try {
      await _firestore
          .collection(userCollection)
          .doc(userId)
          .collection(fcmTokensCollection)
          .doc(deviceToken) // Use token as document ID for uniqueness
          .set({
            'token': deviceToken,
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });

      // Also store in memory for immediate access
      _userTokens[userId] = deviceToken;
      print('Token stored in Firestore and memory for user: $userId');
    } catch (e) {
      print('Error storing token in Firestore: $e');
    }
  }

  // Get token from Firestore for a specific user
  static Future<String?> getTokenFromFirestore(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(userCollection)
          .doc(userId)
          .collection(fcmTokensCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String token = querySnapshot.docs.first['token'];
        // Cache in memory for future use
        _userTokens[userId] = token;
        return token;
      }
      return null;
    } catch (e) {
      print('Error getting token from Firestore: $e');
      return null;
    }
  }

  // Get all active tokens for a user (in case user has multiple devices)
  static Future<List<String>> getAllUserTokens(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(userCollection)
          .doc(userId)
          .collection(fcmTokensCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) => doc['token'] as String).toList();
    } catch (e) {
      print('Error getting all user tokens: $e');
      return [];
    }
  }

  // Mark token as inactive when user logs out or token becomes invalid
  static Future<void> deactivateToken(String userId, String deviceToken) async {
    try {
      await _firestore
          .collection(userCollection)
          .doc(userId)
          .collection(fcmTokensCollection)
          .doc(deviceToken)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Remove from memory cache
      _userTokens.remove(userId);
      print('Token deactivated for user: $userId');
    } catch (e) {
      print('Error deactivating token: $e');
    }
  }

  // Send to multiple users by their IDs
  static Future<bool> sendNotificationToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String serverKey,
  }) async {
    try {
      if (userIds.isEmpty) {
        print('No user IDs provided');
        return false;
      }

      bool allSuccess = true;

      for (String userId in userIds) {
        bool success = await sendNotificationToUserById(
          targetUserId: userId,
          title: title,
          body: body,
          data: data,
          serverKey: serverKey,
        );

        if (!success) {
          allSuccess = false;
          print('Failed to send to user: $userId');
        }

        // Add small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return allSuccess;
    } catch (e) {
      print('Error sending to multiple users: $e');
      return false;
    }
  }

  // Handle token refresh
  static Future<void> handleTokenRefresh() async {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');
      _currentUserToken = newToken;

      if (_currentUserId != null) {
        // Store new token in Firestore and memory
        await _storeTokenInFirestore(_currentUserId!, newToken);
        print('Refreshed token stored for user: $_currentUserId');
      }
    });
  }

  // Update user targeting with Firestore integration
  static Future<void> updateUserTargeting({
    String? userId,
    String? deviceToken,
    String? location,
    Map<String, String>? metadata,
  }) async {
    try {
      // If userId and deviceToken provided, register the token
      if (userId != null && deviceToken != null) {
        await registerUserToken(
          userId: userId,
          deviceToken: deviceToken,
          location: location,
          metadata: metadata,
        );
      }

      // Update Firestore with location/metadata if userId is available
      if (userId != null && (location != null || metadata != null)) {
        Map<String, dynamic> updateData = {};

        if (location != null) {
          updateData['location'] = location;
        }

        if (metadata != null) {
          updateData['metadata'] = metadata;
        }

        updateData['updatedAt'] = FieldValue.serverTimestamp();

        await _firestore
            .collection(userCollection)
            .doc(userId)
            .update(updateData);
      }

      print('User targeting updated successfully');
    } catch (e) {
      print('Update user targeting error: $e');
    }
  }

  static Future<void> registerUserToken({
    required String userId,
    required String deviceToken,
    String? location,
    Map<String, String>? metadata,
  }) async {
    // Store in memory for backward compatibility
    _userTokens[userId] = deviceToken;

    // Store in Firestore (preferred method)
    await _storeTokenInFirestore(userId, deviceToken);

    // Handle location-based storage
    if (location != null) {
      String cleanLocation = location.toLowerCase().replaceAll(' ', '_');
      _locationTokens[cleanLocation] ??= [];
      if (!_locationTokens[cleanLocation]!.contains(deviceToken)) {
        _locationTokens[cleanLocation]!.add(deviceToken);
      }
    }

    // Handle metadata-based storage
    if (metadata != null) {
      for (String key in metadata.keys) {
        _metadataTokens[key] ??= [];
        if (!_metadataTokens[key]!.contains(deviceToken)) {
          _metadataTokens[key]!.add(deviceToken);
        }
      }
    }
  }

  // Get user info from Firestore
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection(userCollection).doc(userId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  // FIXED: Load user tokens from Firestore into memory cache
  static Future<void> loadUserTokensFromFirestore() async {
    try {
      if (_currentUserId != null) {
        String? token = await getTokenFromFirestore(_currentUserId!);
        if (token != null) {
          _userTokens[_currentUserId!] = token;
          print('Loaded token for current user from Firestore');
        }
      }
    } catch (e) {
      print('Error loading tokens from Firestore: $e');
    }
  }

  static Future<String> getDeviceToken() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await _firebaseMessaging.getToken();
    print('Token => $token');
    return token!;
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

      final response = await http
          .post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$serverKey',
            },
            body: jsonEncode({
              'to': deviceToken,
              'notification': {
                'title': title,
                'body': body,
                'sound': 'default',
              },
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
          )
          .timeout(const Duration(seconds: 30)); // Add timeout

      print('FCM Response: ${response.statusCode}');
      print('FCM Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['failure'] == 1) {
          print('FCM reported failure: ${responseBody['results']}');
          return false;
        }
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

  // FIXED: Send to specific user by ID (using stored token with Firestore fallback)
  static Future<bool> sendNotificationToUserById({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String serverKey,
  }) async {
    try {
      String? deviceToken;

      // First try to get from memory cache
      if (_userTokens.containsKey(targetUserId)) {
        deviceToken = _userTokens[targetUserId];
        print('✅ Found token in memory for user: $targetUserId');
      } else {
        // If not in memory, try to get from Firestore
        print(
          '⚠️ Token not found in memory, checking Firestore for user: $targetUserId',
        );
        deviceToken = await getTokenFromFirestore(targetUserId);

        if (deviceToken != null) {
          print('✅ Found token in Firestore for user: $targetUserId');
        } else {
          print('❌ No device token found for user: $targetUserId');
          return false;
        }
      }

      return await sendNotificationToDevice(
        deviceToken: deviceToken!,
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
        print('No device tokens provided');
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
        print('No devices registered for location: $targetLocation');
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

  // FIXED: Get user targeting info with better details
  static Future<Map<String, dynamic>> getUserTargetingInfo() async {
    // Load any missing tokens from Firestore
    await loadUserTokensFromFirestore();

    return {
      'currentUserId': _currentUserId ?? 'Not set',
      'currentUserToken': _currentUserToken != null
          ? '${_currentUserToken!.substring(0, 10)}...'
          : 'Not set',
      'registeredUsers': _userTokens.length,
      'registeredUsersDetails': _userTokens.keys.toList(),
      'registeredLocations': _locationTokens.length,
      'registeredMetadata': _metadataTokens.length,
      'memoryTokenCount': _userTokens.length,
      'hasCurrentUserToken':
          _currentUserId != null && _userTokens.containsKey(_currentUserId!),
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

  static Future<void> cleanupInvalidTokens(String userId) async {
    try {
      final tokens = await getAllUserTokens(userId);
      for (String token in tokens) {
        // Test if token is still valid by sending a test notification
        // If it fails, mark as inactive
      }
    } catch (e) {
      print('Error cleaning up tokens: $e');
    }
  }
}
