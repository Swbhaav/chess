import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:chessgame/values/constant.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/auth/auth_service.dart';

const channel = 'Test';

class AgoraCall extends StatefulWidget {
  final AuthService authService = AuthService();
  final String receiverID;
  final String receiverName;
  AgoraCall({super.key, required this.receiverID, required this.receiverName});

  @override
  State<AgoraCall> createState() => _AgoraCallState();
}

class _AgoraCallState extends State<AgoraCall> {
  int? _remoteUid;
  bool _localUserJoined = false;
  RtcEngine? _engine;
  bool _engineInitialized = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _initializeAgoraVoiceSDK();
  }

  // Set up the Agora RTC engine instance
  Future<void> _initializeAgoraVoiceSDK() async {
    if (_engineInitialized) return;

    await _requestPermissions();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(
        appId: AppInfo.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    _setupEventHandlers();
    await _engine!.enableVideo();
    await _engine!.startPreview();

    setState(() {
      _engineInitialized = true;
    });

    debugPrint("Agora engine initialized successfully");
  }

  // Register an event handler for Agora RTC
  void _setupEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
            _isJoining = false;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint("Remote user $remoteUid left");
              setState(() => _remoteUid = null);
            },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora error: $err - $msg");
          setState(() => _isJoining = false);
        },
      ),
    );
  }

  // Join a channel
  Future<void> _joinChannel() async {
    setState(() => _isJoining = true);

    try {
      if (!_engineInitialized) {
        await _initializeAgoraVoiceSDK();
      }

      await _engine!.joinChannel(
        token: AppInfo.token,
        channelId: channel,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
        uid: 0,
      );

      debugPrint("Attempting to join channel: $channel");
    } catch (e) {
      debugPrint("Error joining channel: $e");
      setState(() => _isJoining = false);
    }
  }

  // Leave channel
  Future<void> _leaveChannel() async {
    await _engine!.leaveChannel();
    setState(() {
      _localUserJoined = false;
      _remoteUid = null;
      _isJoining = false; // Reset joining state
    });
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    statuses.forEach((permission, status) {
      debugPrint("$permission: $status");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            // Local video view
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: _localUserJoined
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : Center(
                      child: _isJoining
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 10),
                                const Text('Joining call...'),
                              ],
                            )
                          : const Text('Press "Start video call" to begin'),
                    ),
            ),
            const SizedBox(height: 10),
            // Remote video view
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: _remoteUid != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine!,
                        canvas: VideoCanvas(uid: _remoteUid),
                        connection: const RtcConnection(channelId: channel),
                      ),
                    )
                  : const Center(child: Text('Waiting for remote user...')),
            ),
            const SizedBox(height: 10),
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isJoining || _localUserJoined
                      ? null
                      : _joinChannel,
                  child: Text(
                    _localUserJoined
                        ? 'Connected'
                        : _isJoining
                        ? 'Connecting...'
                        : 'Start video call',
                  ),
                ),
                ElevatedButton(
                  onPressed: _localUserJoined ? _leaveChannel : null,
                  child: const Text('Leave call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
