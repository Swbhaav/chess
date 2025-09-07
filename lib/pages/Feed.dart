import 'dart:math';

import 'package:chessgame/pages/youtubePages/videopage.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

final videoUrls = [
  'https://youtu.be/xqF3ne87BtA',
  'https://youtu.be/XWuEVkL7IYU',
  'https://youtu.be/C9geh5yxhEc',
  'https://youtu.be/UEBrimIN5r8',
  'https://youtu.be/EvnLpBC4c-k',
  'https://youtu.be/qxK0FvLf_yg',
];

class Feed extends StatelessWidget {
  const Feed({super.key});
  static String getRandomVideoUrl() {
    final random = Random();
    final url = videoUrls[random.nextInt(videoUrls.length)];
    return YoutubePlayer.convertUrlToId(url)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        title: const Text("Flutter YouTube"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: ListView.builder(
        itemCount: videoUrls.length,
        itemBuilder: (context, index) {
          final videoID = YoutubePlayer.convertUrlToId(videoUrls[index]);

          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VideoPage(videoId: videoID),
                ),
              );
            },
            child: Image.network(YoutubePlayer.getThumbnail(videoId: videoID!)),
          );
        },
      ),
    );
  }

  Widget thubmNail() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(10),
      color: Colors.blue,
      child: Center(child: Text('Thumbnail')),
    );
  }
}
