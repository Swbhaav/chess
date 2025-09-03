import 'package:chessgame/services/notification/noti_service.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final notiService = NotiService();

  // Get Current time
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                try {
                  // Ensure initialization before showing notification
                  await notiService.scheduleNotification(
                    title: 'WATCH THIS VIDEO',
                    body: 'YOU HAVE A NEW NOTIFICATION',
                    payload: '/video_page',
                    hour: 18,
                    minute: 0,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notification Scheduled! for 6:00 PM!'),
                    ),
                  );
                } catch (e) {
                  print('Error: $e'); // Debug log
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send notification: $e')),
                  );
                }
              },
              child: const Text(
                'Set Reminder',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                try {
                  // Ensure initialization before showing notification
                  await notiService.showNotification(
                    title: 'Chess Game Alert, WATCH THIS VIDEO',
                    body: 'You have a new notification!',
                    payload: '/video_page',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification sent!')),
                  );
                } catch (e) {
                  print('Error: $e'); // Debug log
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send notification: $e')),
                  );
                }
              },

              child: const Text(
                'Send Notification Now',
                style: TextStyle(color: Colors.white),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                try {
                  await notiService.cancelAllNotifications();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications cancelled !'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error canceling notifications: $e');
                }
              },
              child: const Text(
                'Cancle all',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
