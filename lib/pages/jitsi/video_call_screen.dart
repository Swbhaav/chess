import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

import '../../services/auth/auth_service.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final AuthService _auth = AuthService();
  late TextEditingController meetingIdController;
  late TextEditingController nameController;
  bool isAudioMuted = true;
  bool isVideoMuted = true;
  final JitsiMeet _jitsiMeet = JitsiMeet();

  @override
  void initState() {
    meetingIdController = TextEditingController();
    nameController = TextEditingController(text: _auth.getCurrentUser()!.email);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    meetingIdController.dispose();
    nameController.dispose();
  }

  Future<void> _joinMeeting() async {
    if (meetingIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting ID')),
      );
      return;
    }

    try {
      var options = JitsiMeetConferenceOptions(
        room: meetingIdController.text,
        configOverrides: {
          // Use configOverrides instead of config
          "startWithAudioMuted": isAudioMuted,
          "startWithVideoMuted": isVideoMuted,
          "subject": "Jitsi with Flutter",
        },
        userInfo: JitsiMeetUserInfo(
          displayName: nameController.text,
          email: _auth.getCurrentUser()!.email,
        ),
        featureFlags: {
          "pip.enabled": false,
          "fullscreen.enabled": false,
          "welcomepage.enabled": false,
          "prejoinpage.enabled": false,
        },
      );

      // For older versions, the meeting will open in a separate native view
      // Embedded view is not available in this version
      await _jitsiMeet.join(options);
    } catch (e) {
      print('Error Joining Meeting: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to Join Meeting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Meeting'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: meetingIdController,
              maxLines: 1,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                fillColor: Colors.grey,
                filled: true,
                border: InputBorder.none,
                hintText: 'Room ID',
                contentPadding: EdgeInsets.fromLTRB(16, 8, 5, 5),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              maxLines: 1,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                fillColor: Colors.grey,
                filled: true,
                border: InputBorder.none,
                hintText: 'Your Name',
                contentPadding: EdgeInsets.fromLTRB(16, 8, 5, 5),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    isAudioMuted ? Icons.mic_off : Icons.mic,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () {
                    setState(() {
                      isAudioMuted = !isAudioMuted;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    isVideoMuted ? Icons.videocam_off : Icons.videocam,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () {
                    setState(() {
                      isVideoMuted = !isVideoMuted;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinMeeting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Join Meeting',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
