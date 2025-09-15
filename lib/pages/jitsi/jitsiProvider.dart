// import 'package:chessgame/services/auth/auth_service.dart';
// import 'package:chessgame/services/chat/chatService.dart';
// import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
//
// class JitsiProvider {
//   final AuthService _authService = AuthService();
//   void createMeeting({
//     required String roomName,
//     required bool isAudioMuted,
//     required bool isVideoMuted,
//     String username = '',
//     String email = '',
//     bool preJoined = true,
//     bool isVideo = true,
//     bool isGroup = true,
//   }) async {
//     try {
//       Map<String, Object> featureFlag = {};
//       featureFlag['welcomepage.enabled'] = false;
//       featureFlag['prejoinpage.enabled'] = preJoined;
//       featureFlag['add-people.enabled'] = isGroup;
//
//       var options = JitsiMeetConferenceOptions(
//         room: roomName,
//         configOverrides: {
//           "startWithAudioMuted": isAudioMuted,
//           "startWithVideoMuted": isVideoMuted,
//           "subject": "Call",
//         },
//         userInfo: JitsiMeetUserInfo(
//           displayName: _authService.getCurrentUser()!.email,
//         ),
//         featureFlags: featureFlag,
//       );
//       var jitsiMeet = JitsiMeet();
//       await jitsiMeet.join(options);
//     } catch (error) {
//       print("Errors: $error");
//     }
//   }
// }
