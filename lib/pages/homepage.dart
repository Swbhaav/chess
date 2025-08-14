
import 'package:flutter/material.dart';

import '../game_board.dart';
import 'chat_page.dart';
import 'videopage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int myIndex = 0; // Default index is 0, so the "Video" page is shown initially

  // Define the widget list for navigation
  List<Widget> pages = [
    GameBoard(),
    VideoPage(),
    ChatPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index:  myIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        onTap: (index) {
          setState(() {
            myIndex = index; // Update the selected index
          });
        },
        currentIndex: myIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.games_outlined),
            label: 'Chess',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_collection),
            label: 'Video',
            backgroundColor: Colors.blueAccent,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
            backgroundColor: Colors.deepPurpleAccent,
          ),
        ],
      ),
    );
  }
}
