import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayWidgetState extends StatefulWidget {
  const OverlayWidgetState({super.key});

  @override
  State<OverlayWidgetState> createState() => _OverlayWidgetStateState();
}

class _OverlayWidgetStateState extends State<OverlayWidgetState> {
  Color color = const Color(0xFFFFFFFF);
  BoxShape _currentShape = BoxShape.circle;
  static const String _kPortNameOverlay = 'OVERLAY';
  static const String _kPortNameHome = 'UI';
  final _receiverPort = ReceivePort();
  SendPort? homePort;
  String? messageFromOverlay;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      child: GestureDetector(
        onTap: () async {
          if (_currentShape == BoxShape.rectangle) {
            await FlutterOverlayWindow.resizeOverlay(50, 100, true);
            setState(() {
              _currentShape = BoxShape.circle;
            });
          } else {
            await FlutterOverlayWindow.resizeOverlay(
              WindowSize.matchParent,
              WindowSize.matchParent,
              false,
            );
            setState(() {
              _currentShape = BoxShape.rectangle;
            });
          }
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: Colors.white, shape: _currentShape),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _currentShape == BoxShape.rectangle
                    ? SizedBox(
                        width: 200.0,
                        child: TextButton(
                          onPressed: () {
                            homePort ??= IsolateNameServer.lookupPortByName(
                              _kPortNameHome,
                            );
                            homePort?.send('Date: ${DateTime.now()}');
                          },
                          child: const Text('Send message to UI'),
                        ),
                      )
                    : const SizedBox.shrink(),
                _currentShape == BoxShape.rectangle
                    ? messageFromOverlay == null
                          ? const FlutterLogo()
                          : Text(messageFromOverlay ?? '')
                    : const FlutterLogo(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
