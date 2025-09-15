import 'package:chessgame/services/notification/serverKey.dart';
import 'package:flutter/material.dart';
import '../services/notification/enhanced_noti_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Controllers for targeting inputs
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  GetServerKey getServerKey = GetServerKey();

  // Get Current time
  TimeOfDay selectedTime = TimeOfDay.now();

  // Selected targeting options
  String _selectedTargetType = 'immediate'; // immediate, user, location

  @override
  void initState() {
    super.initState();
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    _titleController.text = 'Chess Game Alert';
    _bodyController.text = 'You have a new notification!';
    _userIdController.text = 'hari_123'; // Default for testing
    _locationController.text = 'Japan'; // Default for testing
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _locationController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Widget _buildTargetingSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Targeting',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Title and Body inputs
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Notification Body',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Target type selection
            const Text('Target Type:'),
            RadioListTile<String>(
              title: const Text('Send Immediately (Local)'),
              value: 'immediate',
              groupValue: _selectedTargetType,
              onChanged: (value) =>
                  setState(() => _selectedTargetType = value!),
            ),
            RadioListTile<String>(
              title: const Text('Target Specific User'),
              value: 'user',
              groupValue: _selectedTargetType,
              onChanged: (value) =>
                  setState(() => _selectedTargetType = value!),
            ),
            RadioListTile<String>(
              title: const Text('Target Location'),
              value: 'location',
              groupValue: _selectedTargetType,
              onChanged: (value) =>
                  setState(() => _selectedTargetType = value!),
            ),

            // Conditional input fields based on target type
            if (_selectedTargetType == 'user') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'Target User ID (e.g., hari_123)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            if (_selectedTargetType == 'location') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Target Location (e.g., Japan)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendTargetedNotification() async {
    try {
      String title = _titleController.text.trim();
      String body = _bodyController.text.trim();

      if (title.isEmpty || body.isEmpty) {
        _showSnackBar('Please enter title and body', Colors.red);
        return;
      }

      bool success = false;
      Map<String, dynamic> data = {
        'type': 'general',
        'timestamp': DateTime.now().toString(),
        'route': '/video_page',
      };

      switch (_selectedTargetType) {
        case 'immediate':
          // Use local notification (immediate)
          await EnhancedNotificationService.showLocalChatNotification(
            senderName: title,
            message: body,
            chatData: data,
          );
          success = true;
          break;

        case 'user':
          String userId = _userIdController.text.trim();
          if (userId.isEmpty) {
            _showSnackBar('Please enter User ID', Colors.red);
            return;
          }
          success =
              await EnhancedNotificationService.sendNotificationToUserById(
                targetUserId: userId,
                title: title,
                body: body,
                data: data,
                serverKey: await getServerKey.getServerKeyToken(),
              );
          break;

        case 'location':
          String location = _locationController.text.trim();
          if (location.isEmpty) {
            _showSnackBar('Please enter location', Colors.red);
            return;
          }
          success =
              await EnhancedNotificationService.sendNotificationToLocation(
                targetLocation: location,
                title: title,
                body: body,
                data: data,
                serverKey: await getServerKey.getServerKeyToken(),
              );
          break;
      }

      if (success || _selectedTargetType == 'immediate') {
        _showSnackBar('Notification sent successfully!', Colors.green);
      } else {
        _showSnackBar('Failed to send notification', Colors.red);
      }
    } catch (e) {
      print('Error sending notification: $e');
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _sendScheduledReminder() async {
    try {
      // This uses the existing local notification scheduling
      await EnhancedNotificationService.scheduleGameReminder(
        opponentName: 'Scheduled Opponent',
        hour: 18,
        minute: 0,
      );
      _showSnackBar('Reminder scheduled for 6:00 PM!', Colors.green);
    } catch (e) {
      print('Error scheduling reminder: $e');
      _showSnackBar('Failed to schedule reminder: $e', Colors.red);
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await EnhancedNotificationService.cancelAllNotifications();
      _showSnackBar('All notifications cancelled!', Colors.red);
    } catch (e) {
      print('Error canceling notifications: $e');
      _showSnackBar('Error canceling notifications: $e', Colors.red);
    }
  }

  Future<void> _getCurrentToken() async {
    try {
      String? token = await EnhancedNotificationService.getToken();
      if (token != null) {
        _showDialog('FCM Token', token);
      } else {
        _showSnackBar('Could not get FCM token', Colors.red);
      }
    } catch (e) {
      print('Error getting token: $e');
      _showSnackBar('Error getting token: $e', Colors.red);
    }
  }

  void _showUserTargetingInfo() {
    Map<String, dynamic> info =
        EnhancedNotificationService.getUserTargetingInfo();
    _showDialog('Current User Targeting', info.toString());
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SelectableText(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Enhanced Notifications'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Targeting configuration section
            _buildTargetingSection(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Main send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _sendTargetedNotification,
                      child: const Text(
                        'Send Targeted Notification',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          onPressed: _sendScheduledReminder,
                          child: const Text(
                            'Schedule Reminder',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: _getCurrentToken,
                          child: const Text(
                            'Get FCM Token',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: _showUserTargetingInfo,
                          child: const Text(
                            'Show Targeting Info',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _cancelAllNotifications,
                      child: const Text(
                        'Cancel All Notifications',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
