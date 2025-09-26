import 'dart:io';
import 'package:chessgame/pages/Feed.dart';
import 'package:chessgame/pages/youtubePages/videoPlayer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import '../googleDriveVideo.dart';

class Drivevideo extends StatefulWidget {
  final String videoUrl;
  const Drivevideo({super.key, required this.videoUrl});

  @override
  State<Drivevideo> createState() => _DrivevideoState();
}

class _DrivevideoState extends State<Drivevideo> with WidgetsBindingObserver {
  final drive = GoogleDrive();
  bool _isUploading = false;
  String? _uploadStatus;
  List<String> _uploadHistory = [];
  List<Map<String, String>> _videoList = []; // Store video names and IDs
  late VideoPlayerController _controller;
  late AudioPlayer _audioPlayer;
  bool _isVideoMode = true;
  bool _isInitialized = false;

  // ➡️ Added to store last playback position
  Duration _lastPosition = Duration.zero;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/drive.metadata.readonly',
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _initializeVideoPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Save current position before switching
        if (_controller.value.isInitialized) {
          _lastPosition = _controller.value.position;
        }
        // App is going to background - switch to audio-only mode
        _switchToAudioMode();
        break;
      case AppLifecycleState.resumed:
        // App is coming to foreground - switch back to video mode
        _switchToVideoMode();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  // Play video from Google Drive
  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..addListener(() {
        if (mounted && _controller.value.isInitialized) {
          // ➡️ Continuously store current position
          _lastPosition = _controller.value.position;
          setState(() {});
        }
      })
      ..setLooping(true)
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
                _controller.play();
              });
            }
          })
          .catchError((error) {
            print('Video initialization error: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load video: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
  }

  Future<void> _switchToAudioMode() async {
    if (!_controller.value.isPlaying) return;

    try {
      // Get current playback position
      _lastPosition = _controller.value.position;

      // Pause video
      await _controller.pause();

      // Start audio playback from the same position
      await _audioPlayer.setUrl(widget.videoUrl);
      await _audioPlayer.seek(_lastPosition);
      await _audioPlayer.play();

      setState(() {
        _isVideoMode = false;
      });
    } catch (e) {
      print('Error switching to audio mode: $e');
    }
  }

  Future<void> _switchToVideoMode() async {
    if (!_audioPlayer.playing) return;

    try {
      // Get current audio position
      _lastPosition = _audioPlayer.position;

      // Stop audio playback
      await _audioPlayer.stop();

      // Ensure video controller is still initialized
      if (!_controller.value.isInitialized) {
        await _controller.initialize();
      }

      // Seek and play from saved position
      await _controller.seekTo(_lastPosition);
      await _controller.play();

      setState(() {
        _isVideoMode = true;
      });
    } catch (e) {
      print('Error switching to video mode: $e');
    }
  }

  void _togglePlayPause() async {
    if (_isVideoMode) {
      // Video mode
      if (_controller.value.isPlaying) {
        await _controller.pause();
      } else {
        await _controller.play();
      }
    } else {
      // Audio mode
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    }
    setState(() {});
  }

  bool get _isPlaying {
    return _isVideoMode
        ? (_controller.value.isInitialized && _controller.value.isPlaying)
        : _audioPlayer.playing;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Drive Video ${_isVideoMode ? "(Video)" : "(Audio Only)"}'),
        actions: [
          IconButton(
            onPressed: _isUploading ? null : _pickAndUploadVideo,
            icon: const Icon(Icons.upload),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: _isVideoMode && _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : _isVideoMode
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.audiotrack, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Audio Only Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Video continues playing in background',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            FloatingActionButton(
              onPressed: _togglePlayPause,
              backgroundColor: Colors.deepPurple,
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
