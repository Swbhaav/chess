import 'dart:isolate';
import 'dart:ui';

import 'package:chessgame/services/chat/chathead_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GlobalChatListener {
  static final GlobalChatListener _instance = GlobalChatListener._internal();
  factory GlobalChatListener() => _instance;
  GlobalChatListener._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatHeadService _chatHeadService = ChatHeadService();

  bool _isListening = false;
  String? _currentActiveChat;

  static const String _KPortNameOverlay = 'OVERLAY';
  SendPort? overlayPort;

  void startGlobalMessageListener() {
    if (_isListening) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _isListening = true;

    _firestore
        .collectionGroup('messages')
        .where('receiverID', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            var latestMessage = snapshot.docs.first;
            Map<String, dynamic> data = latestMessage.data();

            String chatRoomId = _getChatRoomIdFromPath(
              latestMessage.reference.path,
            );

            if (chatRoomId != _currentActiveChat) {
              _showChatHeadForMessage(data, chatRoomId);
            }
          }
        });
  }

  void stopGlobalMessageListener() {
    _isListening = false;
  }

  void setActiveChat(String? chatRoomId) {
    _currentActiveChat = chatRoomId;
  }

  String _getChatRoomIdFromPath(String path) {
    List<String> parts = path.split('/');
    return parts.length >= 2 ? parts[1] : '';
  }

  Future<Map<String, dynamic>?> _getSenderInfo(String senderID) async {
    try {
      DocumentSnapshot senderDoc = await _firestore
          .collection('Users')
          .doc(senderID)
          .get();

      if (senderDoc.exists) {
        return senderDoc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting sender info: $e');
    }
    return null;
  }

  Future<void> _showChatHeadForMessage(
    Map<String, dynamic> messageData,
    String chatRoomId,
  ) async {
    try {
      Map<String, dynamic>? senderInfo = await _getSenderInfo(
        messageData['senderID'],
      );

      if (senderInfo == null) return;

      bool isAppInBackground = await _isAppInBackground();

      if (!isAppInBackground) return;

      final chatHeadData = {
        'senderName': senderInfo['email'] ?? 'Unknown User',
        'message': messageData['message'],
        'unreadCount': 1,
        'chatRoomId': chatRoomId,
        'senderID': messageData['senderID'],
        'timestaamp': messageData['timestamp']
            ?.toDate()
            ?.millisecondsSinceEpoch,
      };

      bool overlayShown = await _chatHeadService.showChatHead();

      if (overlayShown) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _sendDataToOverlay(chatHeadData);
        });
      }
    } catch (e) {
      print('Error showing chat head for message $e');
    }
  }

  void _sendDataToOverlay(Map<String, dynamic> data) {
    try {
      overlayPort ??= IsolateNameServer.lookupPortByName(_KPortNameOverlay);
      overlayPort?.send(data);
    } catch (e) {
      print('Error sending data to overlay: $e');
    }
  }

  Future<bool> _isAppInBackground() async {
    return !_chatHeadService.isOverlayActive;
  }

  static void initialize() {
    GlobalChatListener().startGlobalMessageListener();
  }

  static void dispose() {
    GlobalChatListener().stopGlobalMessageListener();
  }
}
