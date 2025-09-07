import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatHeadService {
  static final ChatHeadService _instance = ChatHeadService._internal();
  factory ChatHeadService() => _instance;
  ChatHeadService._internal();

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
        width: 60,
        height: 60,
        startPosition: const OverlayPosition(100, 200),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      bool isNowActive = await FlutterOverlayWindow.isActive();
      print('Overlay started successfully: $isNowActive');

      return isNowActive;
    } catch (e) {
      print('Error showing overlay: $e');
      return false;
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
}
