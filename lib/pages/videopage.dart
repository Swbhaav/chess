
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';


class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final YoutubePlayerController youtubePlayerController =
  YoutubePlayerController(
    initialVideoId: YoutubePlayer.convertUrlToId(
      "https://youtu.be/QieFszQSlSI",
    )!,
    flags: const YoutubePlayerFlags(
      autoPlay: false,
    )
  );
  @override
  void deactivate() {
    // Pauses the video when navigating away from this screen
    youtubePlayerController.pause();
    super.deactivate();
  }
  void dispose(){
    youtubePlayerController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(controller: youtubePlayerController),
      builder: (context, player) {
        return Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
              children: [

                    player,

              ],
            ),
        );
      },
    );
  }
}