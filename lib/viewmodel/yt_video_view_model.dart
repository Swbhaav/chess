import 'package:chessgame/model/yt_video.dart';
import 'package:chessgame/services/youtube/yt_api_services.dart';
import 'package:flutter/cupertino.dart';

class YtVideoViewModel extends ChangeNotifier {
  List<YtVideo> _playListItems = [];
  List<YtVideo> get playListItems => _playListItems;

  getAllVideos() async {
    _playListItems = await YtApiServices().getAllVideosFromPlaylist();
    notifyListeners(); // updates the UI as soon as view model changes
  }
}
