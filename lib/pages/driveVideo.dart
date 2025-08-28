import 'dart:io';
import 'package:chessgame/pages/Feed.dart';
import 'package:chessgame/pages/videoPlayer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'googleDriveVideo.dart';

class Drivevideo extends StatefulWidget {
  const Drivevideo({super.key});

  @override
  State<Drivevideo> createState() => _DrivevideoState();
}

class _DrivevideoState extends State<Drivevideo> {
  final drive = GoogleDrive();
  bool _isUploading = false;
  String? _uploadStatus;
  List<String> _uploadHistory = [];
  List<Map<String, String>> _videoList = []; // Store video names and IDs

  @override
  void initState() {
    super.initState();
    _fetchVideos(); // Fetch videos when widget initializes
  }

  // Fetch list of videos from Google Drive
  Future<void> _fetchVideos() async {
    try {
      var client = await drive.getHttpClient();
      var driveApi = ga.DriveApi(client);
      String? folderId = await drive.getVideoUrl(videoUrls as String);
      if (folderId == null) {
        print("Sign-in first Error");
        return;
      }

      final found = await driveApi.files.list(
        q: "'$folderId' in parents",
        $fields: "files(id, name)",
      );
      final files = found.files;
      if (files != null) {
        setState(() {
          _videoList = files
              .map((file) => {'id': file.id!, 'name': file.name!})
              .toList();
        });
      }
    } catch (e) {
      print("Error fetching videos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching videos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Play video from Google Drive
  void playVideoFromDrive(BuildContext context, String fileName) async {
    final googleDrive = GoogleDrive();
    final videoUrl = await googleDrive.getVideoUrl(fileName);
    if (videoUrl != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Videoplayer(videoUrl: videoUrl),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Pick and upload video
  Future<void> _pickAndUploadVideo() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadStatus = 'Selecting video file';
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File videoFile = File(result.files.single.path!);

        setState(() {
          _uploadStatus = "Uploading ${result.files.single.name}...";
        });

        bool success = await drive.uploadFileToGoogleDrive(videoFile);

        setState(() {
          _isUploading = false;
          if (success) {
            _uploadStatus =
                "Successfully uploaded: ${result.files.single.name}";
            _uploadHistory.insert(
              0,
              "${result.files.single.name} - ${DateTime.now().toString().substring(0, 19)}",
            );
            _fetchVideos(); // Refresh video list after upload
          } else {
            _uploadStatus = "Failed to upload: ${result.files.single.name}";
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success ? 'Video uploaded successfully' : 'Upload failed',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        });
      } else {
        setState(() {
          _isUploading = false;
          _uploadStatus = "No file selected";
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = "Error: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Video'),
        actions: [
          IconButton(
            onPressed: _isUploading ? null : _pickAndUploadVideo,
            icon: const Icon(Icons.upload),
          ),
          IconButton(onPressed: _fetchVideos, icon: const Icon(Icons.download)),
        ],
      ),
      body: Column(
        children: [
          // Upload status
          if (_uploadStatus != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _uploadStatus!,
                style: TextStyle(
                  color: _isUploading ? Colors.blue : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Video list
          Expanded(
            child: ListView.builder(
              itemCount: _videoList.length,
              itemBuilder: (context, index) {
                final video = _videoList[index];
                return ListTile(
                  title: Text(video['name']!),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => playVideoFromDrive(
                    context,
                    video['name']!,
                  ), // Pass file name
                );
              },
            ),
          ),
          // Upload history
          if (_uploadHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                'Upload History:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _uploadHistory.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_uploadHistory[index]));
              },
            ),
          ),
        ],
      ),
    );
  }
}
