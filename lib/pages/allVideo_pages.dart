import 'package:chessgame/pages/Feed.dart';
import 'package:chessgame/pages/driveVideoPages/drive_video_list.dart';
import 'package:chessgame/pages/youtubePages/youtube_home.dart';
import 'package:flutter/material.dart';

import '../component/custom_Card.dart';

class AllVideoPages extends StatelessWidget {
  const AllVideoPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16),
              child: Text(
                'Choose where you want to watch videos from',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // YouTube option
                    VideoOptionCard(
                      icon: Icons.play_circle_filled,
                      title: 'YouTube Videos',
                      subtitle: 'Browse and watch YouTube content',
                      color: Colors.red,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => YoutubeHomePage(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    // Flutter video option
                    VideoOptionCard(
                      icon: Icons.video_library,
                      title: 'Flutter Videos',
                      subtitle: 'Watch Flutter tutorial videos',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (context) => Feed()));
                      },
                    ),

                    SizedBox(height: 20),

                    // Google Drive option
                    // VideoOptionCard(
                    //   icon: Icons.cloud,
                    //   title: 'Google Drive Videos',
                    //   subtitle: 'Access videos from your Drive',
                    //   color: Colors.green,
                    //   onTap: () {
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(builder: (context) => DriveFeed()),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
