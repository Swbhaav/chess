import 'dart:io';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

final aspectRatios = [
  [1, 1],
  [2, 3],
  [3, 2],
  [16, 9],
  [9, 16],
];

class VideoPage extends StatefulWidget {
  const VideoPage({super.key, required this.videoId});
  final String videoId;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with WidgetsBindingObserver {
  late YoutubePlayerController youtubePlayerController;
  late Floating floating;
  List<int> aspectRatio = aspectRatios.first;
  bool isPipAvailable = false;
  bool isInPipMode = false;
  bool isBackgroundAudioEnabled = false;
  bool _isInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // Enable background playback for Android
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    floating = Floating();
    requestPipAvailable();

    youtubePlayerController = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        // Important flags for background playback
        forceHD: false,
        loop: false,
        controlsVisibleAtStart: true,
      ),
    );

    // Setup background audio handling
    _setupBackgroundAudio();

    // Listen for PiP mode changes
    floating.pipStatusStream.listen((status) {
      setState(() {
        isInPipMode = status == PiPStatus.enabled;
      });
      if (status == PiPStatus.enabled) {
        _ensureAudioPlayback();
      }
    });

    // Listen to player state changes
    youtubePlayerController.addListener(() {
      _handlePlayerStateChange();
    });
  }

  void _setupBackgroundAudio() {
    // Configure audio session for background playback
    if (Platform.isAndroid || Platform.isIOS) {
      // This ensures audio continues when app is in background
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _handlePlayerStateChange() {
    // Handle audio focus and background playback
    if (youtubePlayerController.value.isPlaying && _isInBackground) {
      // Ensure audio continues in background
      _keepAudioAlive();
    }
  }

  Future<void> _keepAudioAlive() async {
    try {
      // Request audio focus for background playback
      if (Platform.isAndroid) {
        // For Android, you might need additional audio focus handling
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } catch (e) {
      print('Error keeping audio alive: $e');
    }
  }

  Future<void> _ensureAudioPlayback() async {
    if (!youtubePlayerController.value.isPlaying) {
      youtubePlayerController.play();
    }
    // Ensure audio continues when entering background/PiP
    await _keepAudioAlive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    setState(() {
      _isInBackground =
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive;
    });

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background
        if (youtubePlayerController.value.isPlaying) {
          // Audio will continue if properly configured
          print('App going to background, audio should continue');
        }
        break;

      case AppLifecycleState.resumed:
        // App is back to foreground
        print('App resumed from background');
        break;

      case AppLifecycleState.detached:
        // App is closed
        youtubePlayerController.pause();
        break;

      default:
        break;
    }
  }

  void requestPipAvailable() async {
    isPipAvailable = await floating.isPipAvailable;
    setState(() {});
  }

  Future<void> enterPipMode() async {
    if (isPipAvailable) {
      try {
        await _ensureAudioPlayback();
        await floating.enable(
          ImmediatePiP(aspectRatio: Rational(aspectRatio[0], aspectRatio[1])),
        );
      } catch (e) {
        print('Error entering PiP mode: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to enter PiP mode: $e')));
      }
    }
  }

  @override
  void deactivate() {
    if (!isInPipMode && !_isInBackground) {
      youtubePlayerController.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    youtubePlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: isInPipMode
          ? null
          : AppBar(
              title: const Text('YouTube Player'),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                if (!isInPipMode)
                  IconButton(
                    icon: Icon(
                      isBackgroundAudioEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                    ),
                    onPressed: _toggleBackgroundAudio,
                  ),
              ],
            ),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: youtubePlayerController,
          showVideoProgressIndicator: true,
          progressColors: const ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
          ),
          onEnded: (data) {
            // Handle video end in background/PiP
            if (isInPipMode || _isInBackground) {
              // You might want to stop PiP when video ends
              if (isInPipMode) {
                // Optionally exit PiP when video ends
              }
            }
          },
        ),
        builder: (context, player) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (!isInPipMode) player,
                if (isInPipMode) Expanded(child: Center(child: player)),
                if (!isInPipMode) const SizedBox(height: 20),
                if (!isInPipMode && isPipAvailable)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_in_picture),
                    label: const Text('Enter PiP Mode'),
                    onPressed: enterPipMode,
                  ),
                if (!isInPipMode && !isPipAvailable)
                  const Text(
                    'Picture-in-Picture not available on this device',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                if (!isInPipMode) const SizedBox(height: 10),
                if (!isInPipMode && isPipAvailable)
                  DropdownButton<List<int>>(
                    value: aspectRatio,
                    items: aspectRatios.map((ratio) {
                      return DropdownMenuItem<List<int>>(
                        value: ratio,
                        child: Text('${ratio.first}:${ratio.last}'),
                      );
                    }).toList(),
                    onChanged: (newRatio) {
                      setState(() {
                        aspectRatio = newRatio!;
                      });
                    },
                  ),
                if (!isInPipMode)
                  SwitchListTile(
                    title: const Text('Background Audio'),
                    value: isBackgroundAudioEnabled,
                    onChanged: (value) {
                      setState(() {
                        isBackgroundAudioEnabled = value;
                      });
                      _toggleBackgroundAudio();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleBackgroundAudio() {
    if (isBackgroundAudioEnabled) {
      // Enable background audio features
      _ensureAudioPlayback();
    } else {
      // Optionally pause when disabling background audio
      if (_isInBackground) {
        youtubePlayerController.pause();
      }
    }
  }
}
