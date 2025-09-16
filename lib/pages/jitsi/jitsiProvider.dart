import 'package:chessgame/services/auth/auth_service.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class JitsiProvider {
  final AuthService _authService = AuthService();
  final JitsiMeet _jitsiMeet = JitsiMeet();
  void createMeeting({
    required String roomName,
    required bool isAudioMuted,
    required bool isVideoMuted,
    String username = '',
    String email = '',
    bool isVideo = true,
    bool isGroup = true,
  }) async {
    try {
      String? name;
      if (username.isEmpty) {
        name = _authService.getCurrentUser()!.email;
      } else {
        name = username;
      }
      var options = JitsiMeetConferenceOptions(
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": isAudioMuted,
          "startWithVideoMuted": isVideoMuted,
          "subject": "Call",
          "prejoinPageEnabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: _authService.getCurrentUser()!.email,
        ),
        featureFlags: {
          FeatureFlags.welcomePageEnabled: true,
          FeatureFlags.addPeopleEnabled: true,
          FeatureFlags.preJoinPageEnabled: false,
          FeatureFlags.addPeopleEnabled: true,
          FeatureFlags.lobbyModeEnabled: false,
        },
      );
      var jitsiMeet = JitsiMeet();
      await jitsiMeet.join(options);
    } catch (error) {
      print("Errors: $error");
    }
  }
}
