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
        serverURL: "https://meet.ffmuc.net",
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": isAudioMuted,
          "startWithVideoMuted": isVideoMuted,
          "subject": "Call",
        },
        userInfo: JitsiMeetUserInfo(
          displayName: name,
          email: email.isNotEmpty
              ? email
              : _authService.getCurrentUser()!.email,
        ),
        featureFlags: {
          // Try these different flag formats based on your SDK version
          "welcome-page-enabled": false,
          "add-people-enabled": true,
          "prejoin-page-enabled": false,
          "lobby-mode-enabled": false,
          "pip-enabled": false,
          "fullscreen-enabled": false,

          // Alternative format if the above doesn't work
          "welcomepage.enabled": false,
          "addpeople.enabled": true,
          "prejoinpage.enabled": false,
          "lobbymode.enabled": false,
        },
      );

      await _jitsiMeet.join(options);
    } catch (error) {
      print("Error: $error");
    }
  }

  // Method to get options for embedded view (if supported)
  JitsiMeetConferenceOptions getMeetingOptions({
    required String roomName,
    required bool isAudioMuted,
    required bool isVideoMuted,
    String username = '',
    String email = '',
  }) {
    String? name;
    if (username.isEmpty) {
      name = _authService.getCurrentUser()!.email;
    } else {
      name = username;
    }

    return JitsiMeetConferenceOptions(
      room: roomName,
      configOverrides: {
        "startWithAudioMuted": isAudioMuted,
        "startWithVideoMuted": isVideoMuted,
        "subject": "Call",
      },
      userInfo: JitsiMeetUserInfo(
        displayName: name,
        email: email.isNotEmpty ? email : _authService.getCurrentUser()!.email,
      ),
      featureFlags: {
        "welcome-page-enabled": false,
        "add-people-enabled": true,
        "prejoin-page-enabled": false,
        "lobby-mode-enabled": false,
        "pip-enabled": false,
        "fullscreen-enabled": false,
      },
    );
  }
}
