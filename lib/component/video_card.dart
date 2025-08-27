import 'package:chessgame/model/yt_video.dart';
import 'package:chessgame/pages/yt_video_player.dart';
import 'package:flutter/material.dart';

class YoutubeVideoCard extends StatelessWidget {
  final YtVideo ytVideo;
  const YoutubeVideoCard({super.key, required this.ytVideo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => YoutubeVideoPlayer(videoId: ytVideo.videoId),
          ),
        );
      },
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.4,
        width: double.maxFinite,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Card(
              margin: EdgeInsets.all(10),
              elevation: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(ytVideo.thumbnailUrl),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      ytVideo.videoTitle,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      ytVideo.channelName,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      ytVideo.viewsCount,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
