import 'package:chessgame/component/video_card.dart';
import 'package:chessgame/viewmodel/yt_video_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:chessgame/services/auth/auth_service.dart';
import 'package:file_picker/file_picker.dart';

class YoutubeHomePage extends StatefulWidget {
  YoutubeHomePage({super.key});
  AuthService _authService = AuthService();

  @override
  State<YoutubeHomePage> createState() => _YoutubeHomePageState();
}

class _YoutubeHomePageState extends State<YoutubeHomePage> {
  @override
  void initState() {
    Provider.of<YtVideoViewModel>(context, listen: false).getAllVideos();
    super.initState();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/youtube.upload',
      'https://www.googleapis.com/auth/youtube',
    ],
  );
  Future<void> _handleVideoInsert() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      File videoFile = File(result.files.single.path!);

      GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return;

      try {
        GoogleSignInAuthentication auth = await account.authentication;
        // Add your video upload logic here
        // You would need to use the YouTube API to upload the video
      } catch (e) {
        print('Error during authentication: $e');
        // Handle error appropriately
      }
    }
  }

  // Future<http.Client?> _getAuthenticatedClient() async {
  //   try {
  //     final GoogleSignInAccount? account = await _googleSignIn.signIn();
  //     if (account == null) return null;
  //
  //     final authClient = await _googleSignIn.authenticatedClient();
  //     return authClient;
  //   } catch (e) {
  //     print('Authentication failed: $e');
  //     return null;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Youtube'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(onPressed: _handleVideoInsert, icon: Icon(Icons.upload)),
        ],
      ),
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
