import 'dart:math';

import 'package:chessgame/pages/jitsi/jitsiProvider.dart';
import 'package:chessgame/pages/jitsi/video_call_screen.dart';
import 'package:flutter/material.dart';

import '../../component/MeetingButton.dart';
import '../../services/auth/auth_service.dart';

class Dashboard extends StatelessWidget {
  Dashboard({super.key});
  final JitsiProvider jitsiProvider = JitsiProvider();
  final AuthService _authService = AuthService();
  createNewMeeting() async {
    var random = Random();
    String roomName = (random.nextInt(100000000) + 10000000).toString();
    jitsiProvider.createMeeting(
      roomName: roomName,
      isAudioMuted: true,
      isVideoMuted: true,
    );
  }

  void joinMeeting(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoCallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        title: Text('Jitsi Meet'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Buttons(
                text: 'New Meeting',
                icon: Icons.videocam,
                onTap: createNewMeeting,
              ),

              Buttons(
                text: 'Join Meeting',
                icon: Icons.add,
                onTap: () => joinMeeting(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
