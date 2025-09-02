import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayWidgetState extends StatefulWidget {
  const OverlayWidgetState({super.key});

  @override
  State<OverlayWidgetState> createState() => _OverlayWidgetStateState();
}

class _OverlayWidgetStateState extends State<OverlayWidgetState>
    with SingleTickerProviderStateMixin {
  Color color = const Color(0xFFFFFFFF);
  BoxShape _currentShape = BoxShape.circle;
  static const String _kPortNameOverlay = 'OVERLAY';
  static const String _kPortNameHome = 'UI';
  final _receiverPort = ReceivePort();
  SendPort? homePort;
  String? messageFromOverlay;
  String senderAvatar = 'lib/images/white-king.png';

  String? senderName;
  String? lastMessage;
  String? chatRoomId;
  int unreadCount = 0;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializePortCommunication();
    _animationController.forward();
  }

  void _initializePortCommunication() {
    if (IsolateNameServer.lookupPortByName(_kPortNameOverlay) != null) {
      IsolateNameServer.removePortNameMapping(_kPortNameOverlay);
    }

    IsolateNameServer.registerPortWithName(
      _receiverPort.sendPort,
      _kPortNameOverlay,
    );

    _receiverPort.listen((dynamic data) {
      if (data is Map<String, dynamic>) {
        setState(() {
          senderName = data['senderName'];
          lastMessage = data['message'];
          chatRoomId = data['chatRoomId'];
          unreadCount = data['unreadCount'] ?? 1;
        });

        _showPulseAnimation();
      }
    });
  }

  void _showPulseAnimation() async {
    for (int i = 0; i < 3; i++) {
      await _animationController.forward();
      await _animationController.reverse();
    }
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _receiverPort.close();
    super.dispose();
  }

  void _openChat() {
    homePort ??= IsolateNameServer.lookupPortByName(_kPortNameHome);
    homePort?.send({
      'action': 'openChat',
      'chatRoomId': chatRoomId,
      'senderName': senderName,
    });

    FlutterOverlayWindow.closeOverlay();
  }

  void _dismissChatHead() {
    FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      child: Stack(
        children: [
          if (_currentShape == BoxShape.rectangle) ...[
            GestureDetector(
              onTap: () async {
                await FlutterOverlayWindow.resizeOverlay(75, 100, true);
                setState(() {
                  _currentShape = BoxShape.circle;
                });
              },
              child: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                ),
                child: _buildExapndedChatView(),
              ),
            ),
          ] else ...[
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: GestureDetector(
                    onTap: () async {
                      await FlutterOverlayWindow.resizeOverlay(500, 400, false);
                      setState(() {
                        _currentShape = BoxShape.rectangle;
                      });
                    },
                    onLongPress: _dismissChatHead,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: _buildChatHeadContent(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 4 ? '4+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatHeadContent() {
    if (senderAvatar != null) {
      return ClipOval(child: Image.asset(senderAvatar, fit: BoxFit.cover));
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
      ),
      child: Center(
        child: Text(
          senderName?.substring(0, 1).toUpperCase() ?? 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildExapndedChatView() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: null),
              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                      ),
                    ),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _dismissChatHead,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Message:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage ?? 'No message',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openChat,
                  label: const Text('Open Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _dismissChatHead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
