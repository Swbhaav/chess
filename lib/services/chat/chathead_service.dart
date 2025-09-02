import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatHeadService {
  static final ChatHeadService _instance = ChatHeadService._internal();
  factory ChatHeadService() => _instance;
  ChatHeadService._internal();

  bool _isOverlayActive = false;

  Future<bool> checkOverlayPermission() async {
    try {
      if (await Permission.systemAlertWindow.isGranted) {
        return true;
      }

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

  Future<bool> showChatHead() async {
    try {
      if (_isOverlayActive) {
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
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: 60,
        height: 60,
      );

      _isOverlayActive = true;
      return true;
    } catch (e) {
      print('Error showing overlay: $e');
      return false;
    }
  }

  Future<bool> hideChatHead() async {
    try {
      if (!_isOverlayActive) {
        return true;
      }

      await FlutterOverlayWindow.closeOverlay();

      _isOverlayActive = false;

      return true;
    } catch (e) {
      print('Error hiding overlay: $e');
      return false;
    }
  }

  bool get isOverlayActive => _isOverlayActive;

  Future<void> resizeOverlay(int width, int height, bool isCircle) async {
    try {
      await FlutterOverlayWindow.resizeOverlay(width, height, isCircle);
    } catch (e) {
      print('Error resizing overlay: $e');
    }
  }

  Future<void> updateOverlayPosition(double x, double y) async {
    try {
      final position = OverlayPosition(x, y);
      await FlutterOverlayWindow.moveOverlay(position);
    } catch (e) {
      print('Error updating overlay position');
    }
  }
}
