import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeVideoPlayer extends StatefulWidget {
  final String videoId;

  const YoutubeVideoPlayer({super.key, required this.videoId});

  @override
  State<YoutubeVideoPlayer> createState() => _YoutubeVideoPlayerState();
}

class _YoutubeVideoPlayerState extends State<YoutubeVideoPlayer>
    with WidgetsBindingObserver {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: true,
        loop: false,
        disableDragSeek: false,
        controlsVisibleAtStart: true,
        hideControls: false,
        startAt: 0,
      ),
    );

    super.initState();
    // Update the controller
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fastForward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);

    // This helps to skip 10 sec until we reach video final length
    final videoDuration = _controller.value.metaData.duration;
    if (newPosition <= videoDuration) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(videoDuration);
    }
  }

  void _rewind() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);

    // This helps to skip 10 sec until we reach video final length

    if (newPosition >= Duration.zero) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(Duration.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(controller: _controller),
        builder: (context, player) {
          return Column(
            children: [
              // some widgets
              player,

              //some other widgets
              _buildSeekButtons(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeekButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _rewind,
            label: const Text('10s'),
            icon: Icon(Icons.fast_rewind),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade100,
              foregroundColor: Colors.purple.shade800,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _fastForward,
            label: const Text('10s'),
            icon: Icon(Icons.skip_next),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade100,
              foregroundColor: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
