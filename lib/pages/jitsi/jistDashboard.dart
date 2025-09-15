// import 'dart:math';
//
// import 'package:chessgame/pages/jitsi/jitsiProvider.dart';
// import 'package:flutter/material.dart';
//
// class Dashboard extends StatelessWidget {
//   Dashboard({super.key});
//   final JitsiProvider jitsiProvider = JitsiProvider();
//   createNewMeeting() async {
//     var random = Random();
//     String roomName = (random.nextInt(100000000) + 10000000).toString();
//     jitsiProvider.createMeeting(
//       roomName: roomName,
//       isAudioMuted: true,
//       isVideoMuted: true,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[400],
//       appBar: AppBar(title: Text('Jitsi Meet')),
//       body: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               IconButton(
//                 onPressed: createNewMeeting,
//                 icon: Icon(Icons.missed_video_call_sharp),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
