
import 'package:chessgame/services/chat/chatService.dart';
import 'package:chessgame/values/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:flutter/material.dart';

import '../services/auth/auth_service.dart';
class CallPage extends StatelessWidget {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final String receiverID;
  final String receiverName;

   CallPage({super.key, required this.receiverID, required this.receiverName});
  // Generate a consistent call ID using both user IDs
  String _generateCallID(String currentUserID, String receiverID) {
    List<String> ids = [currentUserID, receiverID];
    ids.sort(); // Sort to ensure consistency regardless of who initiates
    return ids.join('_call'); // e.g., "user1_user2_call"
  }


  @override
  Widget build(BuildContext context) {
    final User? user = _authService.getCurrentUser();
    final String callID = _generateCallID(user!.uid, receiverID);
    return ZegoUIKitPrebuiltCall(
        appID: AppInfo.appId,
        appSign: AppInfo.appSign,
        callID: callID,
        userID: _authService.getCurrentUser()!.uid,
        userName: user.email!,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall());
  }
}
