import 'package:chessgame/pages/chat_page.dart';
import 'package:chessgame/pages/jitsi/jistDashboard.dart';
import 'package:chessgame/pages/youtubePages/payment_pages.dart';
import 'package:flutter/material.dart';

import '../component/custom_Card.dart';
import 'googlemeet/googleMeet.dart';

class ChatOptions extends StatelessWidget {
  const ChatOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16),
              child: Text(
                'Choose a platform to chat',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Firebase option
                    VideoOptionCard(
                      icon: Icons.chat,
                      title: 'Firebase Chat',
                      subtitle: 'Chat with other users through text',
                      color: Colors.red,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => ChatPage()),
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    // Jitsi option
                    VideoOptionCard(
                      icon: Icons.call,
                      title: 'Jitsi Meet',
                      subtitle: 'Chat with other through video call',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => Dashboard()),
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    VideoOptionCard(
                      icon: Icons.videocam,
                      title: 'Google Meet',
                      subtitle: 'Chat with other through video call',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GoogleMeetPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),

                    VideoOptionCard(
                      icon: Icons.payment,
                      title: 'Payment Pages',
                      subtitle: 'Choose among different options for payment',
                      color: Colors.greenAccent,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PaymentPages(),
                          ),
                        );
                      },
                    ),

                    // IconButton(
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => KhaltiSDKDemo(),
                    //       ),
                    //     );
                    //   },
                    //   icon: Icon(Icons.payment, size: 40),
                    //   style: IconButton.styleFrom(
                    //     foregroundColor: Colors.white,
                    //     backgroundColor: Colors.green,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
