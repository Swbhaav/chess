import 'dart:convert';
import 'dart:developer';

import 'package:chessgame/values/constant.dart';
import 'package:http/http.dart' as http;

import '../../model/yt_video.dart';

class YtApiServices {
  String baseUrl = "https://www.googleapis.com/youtube/v3/playlistItems";

  getAllVideosFromPlaylist() async {
    try {
      List<YtVideo> allVideos = [];
      var response = await http.get(
        Uri.parse(
          baseUrl +
              "?part=snippet&playlistId=PLjVLYmrlmjGeA6_i1WOallrMbTzZtBcp8&key=${AppInfo.youtubeApiKey}",
        ),
      );
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        List playlistItems = jsonData['items'];

        for (var videoData in playlistItems) {
          YtVideo video = YtVideo(
            videoId: videoData['snippet']['resourceId']['videoId'],
            videoTitle: videoData['snippet']['title'],
            thumbnailUrl: videoData['snippet']['thumbnails']['maxres']['url'],
            viewsCount: "100K",
            channelName: videoData['snippet']['channelTitle'],
          );
          allVideos.add(video);
        }

        log('The data form yt api is $playlistItems');
      } else {
        log(
          'Unable to get data from youtube api, the status code is ${response.statusCode} and the body is ${response.body}',
        );
      }

      return allVideos;
    } catch (e) {
      throw ('Unable to get data from youtube api because of $e');
    }
  }
}
