import 'package:chessgame/services/notification/noti_service.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notiService = NotiService();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  // Ensure initialization before showing notification
                  await notiService.init();
                  await notiService.showNotification(
                    title: 'Chess Game Alert',
                    body: 'You have a new notification!',
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
              child: const Text('Send Notification Now'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Ensure initialization before showing notification
                  await notiService.init();
                  await notiService.scheduleNotification(
                    title: 'TIME TO PLAY',
                    body: 'YOU HAVE A NEW NOTIFICATION',
                    hour: 18,
                    minute: 39,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification Scheduled!')),);

                } catch (e) {
                  print('Error: $e'); // Debug log
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send notification: $e')),
                  );
                }
              },
              child: const Text('Send Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
