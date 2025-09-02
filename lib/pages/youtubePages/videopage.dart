import 'dart:io';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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

class _VideoPageState extends State<VideoPage> {
  late YoutubePlayerController youtubePlayerController;
  late Floating floating;
  List<int> aspectRatio = aspectRatios.first;
  bool isPipAvailable = false;
  bool isInPipMode = false;
  bool isBackgroundAudioEnabled = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      // For Android, you might need to handle audio focus
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    floating = Floating();
    requestPipAvailable();
    youtubePlayerController = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    );

    // Listen for PiP mode changes
    floating.pipStatusStream.listen((status) {
      setState(() {
        isInPipMode = status == PiPStatus.enabled;
      });
      if (status == PiPStatus.enabled) {
        // Ensure audio continues when entering PiP
        if (!youtubePlayerController.value.isPlaying) {
          youtubePlayerController.play();
        }
      }
    });
  }

  void requestPipAvailable() async {
    isPipAvailable = await floating.isPipAvailable;
    setState(() {});
  }

  // Method to enter Picture-in-Picture mode
  Future<void> enterPipMode() async {
    if (isPipAvailable) {
      try {
        if (!youtubePlayerController.value.isPlaying) {
          youtubePlayerController.play();
        }
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
    // Only pause if not entering PiP mode
    if (!isInPipMode) {
      youtubePlayerController.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    youtubePlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isInPipMode ? null : AppBar(title: const Text('YouTube Player')),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: youtubePlayerController,
          showVideoProgressIndicator: true,
          progressColors: const ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
          ),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
