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
  late Animation<double> _expandAnimation;

  bool _isLongPressing = false;
  bool _isExpanded = false;

  // Chat head dimensions
  static const double chatHeadSize = 100.0;
  static const double expandedWidth = 300.0;
  static const double expandedHeight = 400.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    _initializePortCommunication();
    _animationController.forward();
  }

  void _initializePortCommunication() {
    if (IsolateNameServer.lookupPortByName(_kPortNameOverlay) != null) {
      IsolateNameServer.removePortNameMapping(_kPortNameOverlay);
    }

    if (IsolateNameServer.lookupPortByName(_kPortNameOverlay) == null) {
      IsolateNameServer.registerPortWithName(
        _receiverPort.sendPort,
        _kPortNameOverlay,
      );
    }

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
    if (_isExpanded) return; // Don't pulse if expanded

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

    if (IsolateNameServer.lookupPortByName(_kPortNameOverlay) != null) {
      IsolateNameServer.removePortNameMapping(_kPortNameOverlay);
    }
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

  Future<void> _cleanShutdown() async {
    try {
      // First, reset state to prevent rendering issues
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _currentShape = BoxShape.circle;
        });
      }

      // Stop any running animations
      _animationController.stop();

      // Send close message to home
      homePort ??= IsolateNameServer.lookupPortByName(_kPortNameHome);
      homePort?.send({'action': 'overlayClosed', 'chatRoomId': chatRoomId});

      // Close the overlay
      await FlutterOverlayWindow.closeOverlay();

      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Error during clean shutdown: $e');
    }
  }

  void _dismissChatHead() async {
    await _cleanShutdown();
  }

  // Add this method to handle proper reinitialization
  static Future<bool> isOverlayActive() async {
    try {
      return await FlutterOverlayWindow.isActive();
    } catch (e) {
      print('Error checking overlay status: $e');
      return false;
    }
  }

  static Future<void> ensureOverlayClosed() async {
    try {
      if (await isOverlayActive()) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      print('Error ensuring overlay closed: $e');
    }
  }

  Future<void> _handleTap() async {
    if (_isLongPressing) return;

    try {
      if (!_isExpanded) {
        // Get screen dimensions
        final screenSize = MediaQuery.of(context).size;

        // Calculate center position
        final centerX = (screenSize.width /*- expandedWidth */ ) / 2;
        final centerY = (screenSize.height /*- expandedHeight */ ) / 2;

        // First resize to expanded size
        await FlutterOverlayWindow.resizeOverlay(
          expandedWidth.toInt(),
          expandedHeight.toInt(),
          false, // Don't auto-reposition, we'll handle positioning
        );

        // Then move to center position
        await FlutterOverlayWindow.moveOverlay(
          OverlayPosition(centerX, centerY),
        );

        if (mounted) {
          setState(() {
            _isExpanded = true;
            _currentShape = BoxShape.rectangle;
          });

          // Animate the expansion
          _animationController.reset();
          _animationController.forward();
        }
      }
    } catch (e) {
      print('Error expanding chat head: $e');
    }
  }

  Future<void> _handleCollapse() async {
    if (_isExpanded) {
      try {
        // Animate collapse
        await _animationController.reverse();

        // Resize back to chat head size
        await FlutterOverlayWindow.resizeOverlay(
          chatHeadSize.toInt(),
          chatHeadSize.toInt(),
          true, // Allow auto-repositioning to keep within bounds
        );

        if (mounted) {
          setState(() {
            _isExpanded = false;
            _currentShape = BoxShape.circle;
          });

          // Animate back in
          _animationController.forward();
        }
      } catch (e) {
        print('Error collapsing chat head: $e');
      }
    }
  }

  void _handleLongPressStart() {
    if (_isExpanded) return; // Don't allow long press when expanded

    print('Long press started');
    setState(() {
      _isLongPressing = true;
    });
  }

  void _handleLongPressEnd() {
    if (_isExpanded) return;

    print('Long press ended - dismissing chat head');
    _dismissChatHead();
  }

  void _handleLongPressCancel() {
    if (_isExpanded) return;

    print('Long press cancelled');
    if (mounted) {
      setState(() {
        _isLongPressing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check: If available space is too small, force chat head mode
    final screenSize = MediaQuery.of(context).size;
    final bool hasEnoughSpace =
        screenSize.width >= expandedWidth &&
        screenSize.height >= expandedHeight;

    // Override expanded state if there's not enough space
    final bool shouldShowExpanded = _isExpanded && hasEnoughSpace;

    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      child: Stack(
        children: [
          if (shouldShowExpanded) ...[
            // Expanded chat view with backdrop
            GestureDetector(
              onTap: _handleCollapse,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.1), // Light backdrop
              ),
            ),
            // Centered expanded chat content
            Center(
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _expandAnimation.value,
                    child: Opacity(
                      opacity: _expandAnimation.value,
                      child: Container(
                        width: expandedWidth,
                        height: expandedHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20.0,
                              offset: const Offset(0, 10),
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: _buildExpandedChatView(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            // Chat head in circle form
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: GestureDetector(
                    onTap: _handleTap,
                    onLongPressStart: (_) => _handleLongPressStart(),
                    onLongPressEnd: (_) => _handleLongPressEnd(),
                    onLongPressCancel: _handleLongPressCancel,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale:
                              _pulseAnimation.value *
                              (_isLongPressing ? 0.9 : 1.0),
                          child: Container(
                            width: chatHeadSize,
                            height: chatHeadSize,
                            decoration: BoxDecoration(
                              color: _isLongPressing ? Colors.red : color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 12.0,
                                  offset: const Offset(0, 6),
                                  spreadRadius: 2.0,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white,
                                width: 4.0,
                              ),
                            ),
                            child: ClipOval(child: _buildChatHeadContent()),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            // Unread count badge
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
    if (senderAvatar.isNotEmpty) {
      return Image.asset(
        senderAvatar,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedChatView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: senderAvatar.isNotEmpty
                      ? AssetImage(senderAvatar)
                      : null,
                  child: senderAvatar.isEmpty
                      ? Text(
                          senderName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _handleCollapse,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: Colors.grey.shade600,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message content area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Preview
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latest Message',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                lastMessage ?? 'No message available',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _openChat,
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text(
                            'Open Chat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _dismissChatHead,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Dismiss',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
