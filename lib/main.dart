import 'package:chessgame/pages/Feed.dart';
import 'package:chessgame/pages/notification_page.dart';
import 'package:chessgame/pages/videopage.dart';
import 'package:chessgame/services/auth/auth_gate.dart';
import 'package:chessgame/services/notification/noti_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase/firebase_options.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();


  // init notification
  final notiService = NotiService();
  await notiService.init(
    onNotificationTap: (payload){
      if(payload == '/video_page'){
        AppNavigator.navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_)=>  VideoPage(videoId: Feed.getRandomVideoUrl()))
        );
      }
    }
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Chess Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}
