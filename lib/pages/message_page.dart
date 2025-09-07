import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:chessgame/component/chat_bubble.dart';
import 'package:chessgame/component/textfield.dart';
import 'package:chessgame/helper/global_chat_listener.dart';
import 'package:chessgame/pages/call_page.dart';
import 'package:chessgame/services/auth/auth_service.dart';
import 'package:chessgame/services/chat/chatService.dart';
import 'package:chessgame/services/chat/chathead_service.dart';
import 'package:chessgame/services/notification/enhanced_noti_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String status;
  MessagePage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
    required this.status,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> with WidgetsBindingObserver {
  // text controller
  final TextEditingController _messageController = TextEditingController();

  //auth an chat service
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatHeadService _chatHeadService = ChatHeadService();

  // for text field focus
  FocusNode myFocusNode = FocusNode();
  bool _isAppInForeground = true;
  String? _currentChatRoomId;

  // Port communication for overlay
  static const String _kPortNameOverlay = 'OVERLAY';
  static const String _kPortNameHome = 'UI';
  final _receiverPort = ReceivePort();
  SendPort? overlayPort;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    String senderID = _authService.getCurrentUser()!.uid;
    _currentChatRoomId = _chatService.getChatRoomID(
      senderID,
      widget.receiverID,
    );

    GlobalChatListener().setActiveChat(_currentChatRoomId);

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), () => scrollDown());
      }
    });

    _initializePortCommunication();
    _listenForNewMessages();
    _startPortMonitor();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await EnhancedNotificationService.initialize(
      onChatNotificationTap: _handleChatNotificationTap,
    );

    String? token = await EnhancedNotificationService.getToken();
    if (token != null) {
      await _storeUserToken(token);
    }
  }

  void _handleChatNotificationTap(Map<String, dynamic> data) {
    print('CHat notification tapped: $data');

    String? chatRoomId = data['chatRoomId'];
    String? senderId = data['senderId'];
    String? senderName = data['senderEmail'];

    if (chatRoomId != null && senderId != null && senderName != null) {
      if (chatRoomId == _currentChatRoomId) {
        Future.delayed(const Duration(milliseconds: 100), () {
          scrollDown();
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              receiverEmail: senderName,
              receiverID: senderId,
              status: 'Online',
            ),
          ),
        );
      }
    }
  }

  Future<void> _storeUserToken(String token) async {
    try {
      String currentUserId = _authService.getCurrentUser()!.uid;
      await _firestore.collection('Users').doc(currentUserId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      print('FCM token stored successfully');
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    myFocusNode.dispose();
    _messageController.dispose();
    _receiverPort.close();

    GlobalChatListener().setActiveChat(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppInForeground = state == AppLifecycleState.resumed;
    });

    if (state == AppLifecycleState.resumed) {
      _checkPermissionAfterResume();
    }
  }

  Future<void> _checkPermissionAfterResume() async {
    bool hasPermission = await _chatHeadService.checkOverlayPermission();
    if (hasPermission) {
      print('Overlay permission granted after resume');
    }
  }

  void _initializePortCommunication() {
    if (IsolateNameServer.lookupPortByName(_kPortNameHome) != null) {
      IsolateNameServer.removePortNameMapping(_kPortNameHome);
    }

    IsolateNameServer.registerPortWithName(
      _receiverPort.sendPort,
      _kPortNameHome,
    );

    _receiverPort.listen((dynamic data) {
      if (data is Map<String, dynamic>) {
        String? action = data['action'];

        switch (action) {
          case 'openChat':
            _handleChatOpenFromOverlay(data);
            break;
          case 'overlayClosed':
            print('Overlay was closed for chat: ${data['chatRoomId']}');
            break;
          default:
            print('Unknown action: $action');
        }
      }
    });
  }

  void _handleChatOpenFromOverlay(Map<String, dynamic> data) {
    print('Received openChat action with data: $data');

    if (data['chatRoomId'] == _currentChatRoomId) {
      print(
        'Chat head tapped for current conversation - bringing to foreground',
      );

      // Bring the current conversation to foreground
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Scroll to bottom to show latest messages
      Future.delayed(const Duration(milliseconds: 100), () {
        scrollDown();
      });
    } else {
      print('Opening different chat from overlay: ${data['chatRoomId']}');

      // Here you would navigate to the different chat
      // But since you're in MessagePage, you might want to handle this globally
      String? senderName = data['senderName'];
      String? chatRoomId = data['chatRoomId'];

      if (senderName != null && chatRoomId != null) {
        // For now, just bring the app to foreground and let user navigate manually
        // Or implement navigation logic here
        Navigator.of(context).popUntil((route) => route.isFirst);

        // You could show a snackbar to inform user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New message from $senderName'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // Navigate to the specific chat
                _navigateToSpecificChat(senderName, chatRoomId);
              },
            ),
          ),
        );
      }
    }
  }

  void _navigateToSpecificChat(String senderName, String chatRoomId) {
    // Extract receiver ID from chatRoomId
    List<String> userIds = chatRoomId.split('_');
    String currentUserId = _authService.getCurrentUser()!.uid;
    String receiverId = userIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => userIds.isNotEmpty ? userIds.first : '',
    );

    if (receiverId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            receiverEmail: senderName,
            receiverID: receiverId,
            status: 'Online',
          ),
        ),
      );
    }
  }

  void _listenForNewMessages() {
    String senderID = _authService.getCurrentUser()!.uid;

    _chatService.getMessages(widget.receiverID, senderID).listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var latestDoc = snapshot.docs.last;
        Map<String, dynamic> data = latestDoc.data() as Map<String, dynamic>;

        if (data['senderID'] != senderID) {
          if (!_isAppInForeground) {
            _showChatHead(data);
          } else {
            _showForegroundNotification(data);
          }
        }
      }
    });
  }

  Future<void> _showForegroundNotification(
    Map<String, dynamic> messageData,
  ) async {
    await EnhancedNotificationService.showLocalChatNotification(
      senderName: widget.receiverEmail,
      message: messageData['message'] ?? 'New message',
      chatData: {
        'type': 'chat_message',
        'chatRoomId': _currentChatRoomId,
        'senderId': widget.receiverID,
        'senderName': widget.receiverEmail,
        'receiverId': _authService.getCurrentUser()!.uid,
        'message': messageData['message'],
      },
    );
  }

  Future<void> _sendPushNotificationToReceiver(String message) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(widget.receiverID)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? receiverToken = userData['fcmToken'];

        if (receiverToken != null) {
          String currentUserEmail =
              _authService.getCurrentUser()!.email ?? 'Unknown';

          await EnhancedNotificationService.sendChatNotification(
            recipientToken: receiverToken,
            senderName: currentUserEmail,
            message: message,
            chatRoomId: _currentChatRoomId!,
            senderId: _authService.getCurrentUser()!.uid,
            receiverId: widget.receiverID,
            serverKey:
                'BDZkoDZ1ENKsI2-XarMR_K5xNv-8ABALzI7QU7huiUVMwnZtU7vfP_tryPffW2wJrbJAZHQjryNF5aTyVYVY44w', // Replace with your server key
          );
        }
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  Future<void> _showChatHead(Map<String, dynamic> messageData) async {
    try {
      bool hasPermission = await _chatHeadService.checkOverlayPermission();
      if (!hasPermission) {
        print('Overlay permission not granted, requesting.. ');

        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }

      bool permissionGranted = await _chatHeadService
          .requestOverlayPermissionWithGuidance();

      if (!permissionGranted) {
        print('User did not grant overlay permission');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      hasPermission = await _chatHeadService.checkOverlayPermission();

      if (!hasPermission) {
        print('Permission chek failed after request');
        return;
      }

      final chatHeadData = {
        'senderName': widget.receiverEmail,
        'message': messageData['message'],
        'unreadCount': 1,
        'chatRoomId': _currentChatRoomId,
        'senderID': widget.receiverID,
      };

      bool overlayShown = await _chatHeadService.showChatHead();

      if (overlayShown) {
        await Future.delayed(const Duration(milliseconds: 800));

        overlayPort = IsolateNameServer.lookupPortByName(_kPortNameOverlay);

        if (overlayPort != null) {
          overlayPort!.send(chatHeadData);
        } else {
          print('Overlay port not available, retrying');
          await Future.delayed(const Duration(milliseconds: 300));
          overlayPort = IsolateNameServer.lookupPortByName(_kPortNameOverlay);
          overlayPort?.send(chatHeadData);
        }
      }
    } catch (e) {
      print('Error showing chat head: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'Chat heads require overlay permission. You will be redirected to system settings to grant this permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _testChatHead() async {
    try {
      // Debug permission status first
      await _chatHeadService.debugPermissionStatus();

      bool success = await _chatHeadService.showChatHeadWithPermissionCheck();

      if (success) {
        print('Test chat head shown successfully');

        await Future.delayed(const Duration(milliseconds: 800));
        await _showChatHead({
          'message':
              'Test Message From ${widget.receiverEmail} - Hold icon to dismiss chat head directly',
          'senderID': widget.receiverID,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat head displayed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Failed to show test chat head');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to show chat head. Check permissions.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in test chat head: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startPortMonitor() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      overlayPort = IsolateNameServer.lookupPortByName(_kPortNameOverlay);
      if (overlayPort != null) {
        print('Overlay port connected');
        timer.cancel();
      }
    });
  }

  //scroll controller
  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverID,
        _messageController.text,
      );

      //clear text controller
      _messageController.clear();
    }
  }
  //
  // Future<void> updateActiveStatus(bool isOnline) async {
  //   final user = _authService.getCurrentUser();
  //   if (user == null) {
  //     print('No authenticated user found');
  //     return;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection("Users")
              .doc(widget.receiverID)
              .snapshots(),
          builder: (context, snapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverEmail),
                Text(widget.status, style: TextStyle(fontSize: 14)),
              ],
            );
          },
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _testChatHead,
            icon: Icon(Icons.chat_bubble),
            tooltip: 'Test chat head',
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallPage(
                      receiverID: widget.receiverID,
                      receiverName: widget.receiverEmail,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.video_chat),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // display all the messages
          Expanded(child: _buildMessageLists()),
          _buildUserInput(),
        ],
      ),
    );
  }

  //build message List
  Widget _buildMessageLists() {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverID, senderID),
      builder: (context, snapshot) {
        //errors
        if (snapshot.hasError) {
          return const Text('Error');
        }

        //loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading..');
        }

        //return list view
        return ListView(
          controller: _scrollController,
          children: snapshot.data!.docs
              .map((doc) => _buildMessageItem(doc))
              .toList(),
        );
      },
    );
  }

  //Build message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;

    var alignment = isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ChatBubble(message: data["message"], isCurrentUser: isCurrentUser),
        ],
      ),
    );
  }

  //build message input
  Widget _buildUserInput() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: MyTextField(
              hint: "Type a message",
              controller: _messageController,
              obscureText: false,
              focusNode: FocusNode(),
            ),
          ),
        ),

        //Send button
        Container(
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.only(right: 25),
          child: IconButton(
            onPressed: sendMessage,
            icon: Icon(Icons.arrow_upward),
          ),
        ),
      ],
    );
  }
}
