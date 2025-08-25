import 'package:chessgame/component/video_card.dart';
import 'package:chessgame/viewmodel/yt_video_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class YoutubeHomePage extends StatefulWidget {
  const YoutubeHomePage({super.key});

  @override
  State<YoutubeHomePage> createState() => _YoutubeHomePageState();
}

class _YoutubeHomePageState extends State<YoutubeHomePage> {
  @override
  void initState() {
    Provider.of<YtVideoViewModel>(context, listen: false).getAllVideos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Youtube'), backgroundColor: Colors.redAccent),
      body: Consumer<YtVideoViewModel>(
        builder: (context, ytVideoViewModel, _) {
          if (ytVideoViewModel.playListItems.isEmpty) {
            return Center(child: Text('There are no videos'));
          } else {
            return ListView.builder(
              itemCount: ytVideoViewModel.playListItems.length,
              itemBuilder: (context, index) {
                return YoutubeVideoCard(
                  ytVideo: ytVideoViewModel.playListItems[0],
                );
              },
            );
          }
        },
      ),
    );
  }
}
