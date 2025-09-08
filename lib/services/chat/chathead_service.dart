import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatHeadService {
  static final ChatHeadService _instance = ChatHeadService._internal();
  factory ChatHeadService() => _instance;
  ChatHeadService._internal();

  static const String _kPortNameHome = 'UI';
  SendPort? overlayPort;

  Future<bool> checkOverlayPermission() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  Future<bool> requestOverlayPermission() async {
    try {
      PermissionStatus status = await Permission.systemAlertWindow.request();

      if (status.isGranted) {
        return true;
      }
      await FlutterOverlayWindow.requestPermission();

      return await checkOverlayPermission();
    } catch (e) {
      print('Error requesting overlay permission: $e');
      return false;
    }
  }

  Future<bool> requestOverlayPermissionWithGuidance() async {
    try {
      bool hasPermission = await checkOverlayPermission();
      if (hasPermission) {
        return true;
      }

      print('Requesting overlay permission - this will open system settings');

      // This should open the system overlay permission settings
      bool? requestResult = await FlutterOverlayWindow.requestPermission();

      if (requestResult == true) {
        // After user comes back from settings, check permission again
        await Future.delayed(const Duration(milliseconds: 500));
        return await checkOverlayPermission();
      }

      // If FlutterOverlayWindow.requestPermission() fails, try alternative method
      try {
        await Permission.systemAlertWindow.request();
        return await checkOverlayPermission();
      } catch (e) {
        print('Alternative permission request also failed: $e');
        return false;
      }
    } catch (e) {
      print('Error requesting overlay permission with guidance: $e');
      return false;
    }
  }

  Future<bool> showChatHead() async {
    try {
      bool isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        print('Overlay is already active');
        return true;
      }
      bool hasPermission = await checkOverlayPermission();
      if (!hasPermission) {
        print('Overlay permission not granted');
        return false;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Chat head",
        overlayContent: 'Overlay Content',
        flag: OverlayFlag.focusPointer,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
        width: 100,
        height: 120,
        startPosition: const OverlayPosition(100, 200),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      _initializePortCommunication();

      bool isNowActive = await FlutterOverlayWindow.isActive();
      print('Overlay started successfully: $isNowActive');

      return isNowActive;
    } catch (e) {
      print('Error showing overlay: $e');
      return false;
    }
  }

  void _initializePortCommunication() {
    try {
      overlayPort = IsolateNameServer.lookupPortByName('OVERLAY');
      print('Overlay port communication initialized: ${overlayPort != null}');
    } catch (e) {
      print('Error initializing port communication: $e');
    }
  }

  Future<bool> showChatHeadForMessage({
    required String senderName,
    required String message,
    required String chatRoomId,
    int unreadCount = 1,
    String? senderAvatar,
  }) async {
    try {
      print('Showing chat head for new message from: $senderName');

      bool hasPermission = await checkOverlayPermission();
      if (!hasPermission) {
        print('No overlay permission - requesting...');
        hasPermission = await requestOverlayPermissionWithGuidance();
        if (!hasPermission) {
          print('Failed to get overlay permission');
          return false;
        }
      }
      bool isActive = await FlutterOverlayWindow.isActive();
      if (!isActive) {
        await showChatHead();

        await Future.delayed(const Duration(milliseconds: 800));
      }

      await _sendMessageToOverlay({
        'senderName': senderName,
        'message': message,
        'chatRoomId': chatRoomId,
        'unredaCount': unreadCount,
        if (senderAvatar != null) 'senderAvatar': senderAvatar,
      });
      return true;
    } catch (e) {
      print('Error showing chat head for message: $e');
      return false;
    }
  }

  Future<bool> updateChatHeadMessage({
    String? senderName,
    String? message,
    String? chatRoomId,
    int? unreadCount,
    String? senderAvatar,
  }) async {
    try {
      bool isActive = await FlutterOverlayWindow.isActive();
      if (!isActive) {
        return false;
      }

      Map<String, dynamic> updateData = {};
      if (senderName != null) updateData['senderName'] = senderName;
      if (message != null) updateData['message'] = message;
      if (chatRoomId != null) updateData['unreadCount'] = unreadCount;
      if (senderAvatar != null) updateData['senderAvatar'] = senderAvatar;

      await _sendMessageToOverlay(updateData);
      return true;
    } catch (e) {
      print('Error updating chat head message: $e');
      return false;
    }
  }

  Future<void> _sendMessageToOverlay(Map<String, dynamic> data) async {
    try {
      if (overlayPort == null) {
        overlayPort = IsolateNameServer.lookupPortByName('OVERLAY');
      }
      if (overlayPort != null) {
        overlayPort!.send(data);
        print('Message sent to overlay; $data');
      } else {
        print('Overlay prot not found - trying alternative method');

        try {
          await FlutterOverlayWindow.shareData(data);
        } catch (e) {
          print('Alternative data sharing also failed: $e');
        }
      }
    } catch (e) {
      print('Error sending message to overlay: $e');
    }
  }

  Future<void> incrementUnreadCount(String chatRoomId) async {
    try {
      bool isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await _sendMessageToOverlay({
          'action': 'incrementUnread',
          'chatRoomId': chatRoomId,
        });
      }
    } catch (e) {
      print('Error incrementing unread count: $e');
    }
  }

  Future<void> clearUnreadCount(String chatRoomId) async {
    try {
      bool isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await _sendMessageToOverlay({
          'action': 'clearUnread',
          'chatRoomId': chatRoomId,
        });
      }
    } catch (e) {
      print('Error clearing unread count: $e');
    }
  }

  Future<bool> showChatHeadWithPermissionCheck() async {
    try {
      bool hasPermission = await checkOverlayPermission();

      if (!hasPermission) {
        print('Permission not granted, requesting...');
        hasPermission = await requestOverlayPermissionWithGuidance();

        if (!hasPermission) {
          print('Failed to get overlay permission');
          return false;
        }
      }

      return await showChatHead();
    } catch (e) {
      print('Error showing chat head with permission check: $e');
      return false;
    }
  }

  Future<bool> hideChatHead() async {
    try {
      bool isActive = await FlutterOverlayWindow.isActive();
      if (!isActive) {
        return true;
      }
      await FlutterOverlayWindow.closeOverlay();

      return true;
    } catch (e) {
      print('Error hiding overlay: $e');
      return false;
    }
  }

  Future<bool> get isOverlayActive async {
    try {
      return await FlutterOverlayWindow.isActive();
    } catch (e) {
      print('Error checking overlay status: $e');
      return false;
    }
  }

  Future<void> resizeOverlay(int width, int height, bool isCircle) async {
    try {
      bool isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.resizeOverlay(width, height, isCircle);
      }
    } catch (e) {
      print('Error resizing overlay: $e');
    }
  }

  // Convenience method to expand chat head
  Future<void> expandChatHead() async {
    await resizeOverlay(350, 350, false);
  }

  // Convenience method to collapse chat head
  Future<void> collapseChatHead() async {
    await resizeOverlay(100, 120, true);
  }

  Future<void> updateOverlayPosition(double x, double y) async {
    try {
      bool isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        final position = OverlayPosition(x, y);
        await FlutterOverlayWindow.moveOverlay(position);
      }
    } catch (e) {
      print('Error updating overlay position');
    }
  }

  Future<bool> restartChatHead() async {
    try {
      bool isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      await Future.delayed(const Duration(milliseconds: 200));

      return await showChatHead();
    } catch (e) {
      print('Error restarting chat head: $e');
      return false;
    }
  }

  static Future<bool> isOverlayRunning() async {
    try {
      return await FlutterOverlayWindow.isActive();
    } catch (e) {
      return false;
    }
  }

  Future<void> debugPermissionStatus() async {
    try {
      bool flutterOverlayPermission =
          await FlutterOverlayWindow.isPermissionGranted();
      bool permissionHandlerStatus =
          await Permission.systemAlertWindow.isGranted;
      bool isActive = await FlutterOverlayWindow.isActive();

      print('=== Permission Debug Info ===');
      print('FlutterOverlayWindow permission: $flutterOverlayPermission');
      print('PermissionHandler systemAlertWindow: $permissionHandlerStatus');
      print('Overlay currently active: $isActive');
      print('============================');
    } catch (e) {
      print('Error debugging permission status: $e');
    }
  }

  static Future<void> onMessageReceived({
    required String senderName,
    required String message,
    required String chatRoomId,
    String? senderAvatar,
  }) async {
    try {
      final chatHeadService = ChatHeadService();

      bool isActive = await chatHeadService.isOverlayActive;

      if (isActive) {
        await chatHeadService.incrementUnreadCount(chatRoomId);
        await chatHeadService.updateChatHeadMessage(
          senderName: senderName,
          message: message,
          chatRoomId: chatRoomId,
          senderAvatar: senderAvatar,
        );
      } else {
        await chatHeadService.showChatHeadForMessage(
          senderName: senderName,
          message: message,
          chatRoomId: chatRoomId,
          unreadCount: 1,
          senderAvatar: senderAvatar,
        );
      }
    } catch (e) {
      print('Error handling received message: $e');
    }
  }
}
