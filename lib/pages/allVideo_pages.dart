import 'package:chessgame/component/button.dart';
import 'package:chessgame/pages/Feed.dart';
import 'package:chessgame/pages/driveVideoPages/drive_video_list.dart';
import 'package:chessgame/pages/youtubePages/youtube_home.dart';
import 'package:flutter/material.dart';

import 'driveVideoPages/driveVideo.dart';

class AllVideoPages extends StatelessWidget {
  const AllVideoPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black38,
      body: Padding(
        padding: const EdgeInsets.all(45.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyButton(
              text: 'Youtube Video Page',
              size: 20,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => YoutubeHomePage()),
                );
              },
            ),

            SizedBox(height: 10),

            MyButton(
              text: 'Flutter Video Page',
              size: 20,
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => Feed()));
              },
            ),

            SizedBox(height: 10),

            MyButton(
              text: 'Google Drive Video',
              size: 20,
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => DriveFeed()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
