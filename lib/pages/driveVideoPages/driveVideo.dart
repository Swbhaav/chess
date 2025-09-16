// import 'dart:io';
// import 'package:chessgame/pages/Feed.dart';
// import 'package:chessgame/pages/youtubePages/videoPlayer.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/drive/v3.dart' as ga;
// import 'package:video_player/video_player.dart';
// import '../googleDriveVideo.dart';
//
// class Drivevideo extends StatefulWidget {
//   final String videoUrl;
//   const Drivevideo({super.key, required this.videoUrl});
//
//   @override
//   State<Drivevideo> createState() => _DrivevideoState();
// }
//
// class _DrivevideoState extends State<Drivevideo> {
//   final drive = GoogleDrive();
//   bool _isUploading = false;
//   String? _uploadStatus;
//   List<String> _uploadHistory = [];
//   List<Map<String, String>> _videoList = []; // Store video names and IDs
//   late VideoPlayerController _controller;
//   static final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: [
//       'https://www.googleapis.com/auth/drive.readonly',
//       'https://www.googleapis.com/auth/drive.metadata.readonly',
//     ],
//   );
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeVideoPlayer();
//   }
//
//   // Play video from Google Drive
//   void _initializeVideoPlayer() {
//     _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
//       ..addListener(() => setState(() {}))
//       ..setLooping(true)
//       ..initialize()
//           .then((_) {
//             if (mounted) {
//               setState(() {
//                 _controller.play();
//               });
//             }
//           })
//           .catchError((error) {
//             print('Video initialization error: $error');
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Failed to load video: $error'),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//           });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   // Pick and upload video
//   Future<void> _pickAndUploadVideo() async {
//     try {
//       setState(() {
//         _isUploading = true;
//         _uploadStatus = 'Selecting video file';
//       });
//
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.video,
//         allowMultiple: false,
//       );
//
//       if (result != null && result.files.single.path != null) {
//         File videoFile = File(result.files.single.path!);
//
//         setState(() {
//           _uploadStatus = "Uploading ${result.files.single.name}...";
//         });
//
//         bool success = await drive.uploadFileToGoogleDrive(videoFile);
//
//         setState(() {
//           _isUploading = false;
//           if (success) {
//             _uploadStatus =
//                 "Successfully uploaded: ${result.files.single.name}";
//             _uploadHistory.insert(
//               0,
//               "${result.files.single.name} - ${DateTime.now().toString().substring(0, 19)}",
//             );
//           } else {
//             _uploadStatus = "Failed to upload: ${result.files.single.name}";
//           }
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   success ? 'Video uploaded successfully' : 'Upload failed',
//                 ),
//                 backgroundColor: success ? Colors.green : Colors.red,
//               ),
//             );
//           }
//         });
//       } else {
//         setState(() {
//           _isUploading = false;
//           _uploadStatus = "No file selected";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _isUploading = false;
//         _uploadStatus = "Error: $e";
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         title: const Text('Drive Video'),
//         actions: [
//           IconButton(
//             onPressed: _isUploading ? null : _pickAndUploadVideo,
//             icon: const Icon(Icons.upload),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             Center(
//               child: _controller.value.isInitialized
//                   ? AspectRatio(
//                       aspectRatio: _controller.value.aspectRatio,
//                       child: VideoPlayer(_controller),
//                     )
//                   : CircularProgressIndicator(),
//             ),
//             const SizedBox(height: 10),
//             FloatingActionButton(
//               onPressed: () {
//                 setState(() {
//                   _controller.value.isPlaying
//                       ? _controller.pause()
//                       : _controller.play();
//                 });
//               },
//
//               child: Icon(
//                 _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//               ),
//             ),
//             SizedBox(height: 10),
//
//             // // Upload status
//             // if (_uploadStatus != null)
//             //   Padding(
//             //     padding: const EdgeInsets.all(8.0),
//             //     child: Text(
//             //       _uploadStatus!,
//             //       style: TextStyle(
//             //         color: _isUploading ? Colors.blue : Colors.black,
//             //         fontWeight: FontWeight.bold,
//             //       ),
//             //     ),
//             //   ),
//             // // Video list
//             // Expanded(
//             //   child: ListView.builder(
//             //     itemCount: _videoList.length,
//             //     itemBuilder: (context, index) {
//             //       final video = _videoList[index];
//             //       return ListTile(
//             //         title: Text(video['name']!),
//             //         trailing: const Icon(Icons.play_arrow),
//             //         onTap: () => playVideoFromDrive(
//             //           context,
//             //           video['name']!,
//             //         ), // Pass file name
//             //       );
//             //     },
//             //   ),
//             // ),
//             // // Upload history
//             // if (_uploadHistory.isNotEmpty)
//             //   Padding(
//             //     padding: const EdgeInsets.all(8.0),
//             //     child: const Text(
//             //       'Upload History:',
//             //       style: TextStyle(fontWeight: FontWeight.bold),
//             //     ),
//             //   ),
//           ],
//         ),
//       ),
//     );
//   }
// }
