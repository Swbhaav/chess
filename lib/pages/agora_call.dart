
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:chessgame/values/constant.dart';
import 'package:flutter/material.dart';


class AgoraCall extends StatefulWidget {
  final String? channelName;
  final ClientRoleType? role;
  const AgoraCall({super.key, this.channelName, this.role});

  @override
  State<AgoraCall> createState() => _AgoraCallState();
}

class _AgoraCallState extends State<AgoraCall> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted= false;
  bool viewPanel = false;
  late RtcEngine _engine;

  @override
  void initState(){
    super.initState();
    initialize();
  }

  @override
  void dispose(){
    _users.clear();
    _engine.leaveChannel();
    super.dispose();
  }

  Future<void> initialize() async{
    if(AppInfo.agoraAppId.isEmpty){
      setState(() {
        _infoStrings.add('App_ID missing, please provide your App_ID in settings.dart');
        _infoStrings.add('Agora Engine is not starting');
      });
      return ;
    }
    _engine = await createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: AppInfo.agoraAppId));
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: widget.role!);

    //agoraEvent Handlers
    _addAgoraEventHandlers();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 1920, height: 1080),);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(
        token: AppInfo.token,
        channelId: widget.channelName!,
        uid: 0,
        options:;
  }
  void _addAgoraEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed){
          debugPrint("Local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined =true;
          });
        },
        onUserJoined: (RtcConnection connection,int remoteUid , int elapsed) {
          print('User joined: $uid');
          setState(() {
            _users.add(uid);
          });
        },
        userOffline: (uid, reason) {
          print('User offline: $uid, reason: $reason');
          setState(() {
            _users.remove(uid);
          });
        },
        error: (code) {
          print('Error: $code');
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
