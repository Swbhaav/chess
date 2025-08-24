import 'package:chessgame/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

// Use StatefulWidget for call invitations
class SimpleCallInvitation extends StatelessWidget {
  final ZegoCallInvitationData invitationData;
  AuthService _authService =AuthService();

   SimpleCallInvitation({
    super.key,
    required this.invitationData,
  });

  @override
  Widget build(BuildContext context) {
    // Very basic implementation without state management
    // This lacks animations, timeout handling, and proper UX
    return AlertDialog(
      title: Text('${_authService.getCurrentUser()} is calling'),
      content: Text(
        invitationData.type == ZegoInvitationType.videoCall
            ? 'Incoming video call'
            : 'Incoming voice call',
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // Correct method name for rejecting
            await ZegoUIKitPrebuiltCallInvitationService()
                .reject(customData: invitationData.invitationID);
            Navigator.of(context).pop();
          },
          child: const Text('Decline'),
        ),
        TextButton(
          onPressed: () async {
            // Correct method name for accepting
            await ZegoUIKitPrebuiltCallInvitationService()
                .accept(customData: invitationData.invitationID);
            Navigator.of(context).pop();
            // Navigate to call screen
          },
          child: const Text('Accept'),
        ),
      ],
    );
  }
}
// Usage example:
class CallInvitationHandler {
  static void showIncomingCall(
      BuildContext context,
      ZegoCallInvitationData invitationData,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleCallInvitation(
        invitationData: invitationData,
      ),
    );
  }

  // Alternative method using bottom sheet
  static void showIncomingCallBottomSheet(
      BuildContext context,
      ZegoCallInvitationData invitationData,
      ) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SimpleCallInvitation(
        invitationData: invitationData,
      ),
    );
  }

  // Method to handle incoming call notifications
  static void handleIncomingCall(
      BuildContext context,
      ZegoCallInvitationData invitationData,
      ) {
    // You can customize how to show the invitation
    // For example, check if app is in foreground/background
    showIncomingCall(context, invitationData);
  }
}