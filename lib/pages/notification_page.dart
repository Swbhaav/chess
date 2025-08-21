import 'package:chessgame/services/notification/noti_service.dart';
import 'package:chessgame/values/colors.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  TextEditingController _hourController = TextEditingController();
  TextEditingController _minuteController = TextEditingController();
  final notiService = NotiService();

  // Get Current time
  TimeOfDay selectedTime = TimeOfDay.now();
  String? _hourError;
  String? _minuteError;

  @override
  void initState() {
    super.initState();
    // Initialize the text field with current time
    _hourController.text = selectedTime.hour.toString();
    _minuteController.text = selectedTime.minute.toString();
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        _hourController.text = selectedTime.hour.toString();
        _minuteController.text = selectedTime.minute.toString();
      });
    }
  }

  // Validate hour input
  String? _validateHour(String? value) {
    if (value == null || value.isEmpty) {
      return 'Hour is required';
    }
    final hour = int.tryParse(value);
    if (hour == null) {
      return 'Enter a valid number';
    }
    if (hour < 0 || hour > 23) {
      return 'Hour must be 0-23';
    }
    return null;
  }

  // Validate minute input
  String? _validateMinute(String? value) {
    if (value == null || value.isEmpty) {
      return 'Minute is required';
    }
    final minute = int.tryParse(value);
    if (minute == null) {
      return 'Enter a valid number';
    }
    if (minute < 0 || minute > 59) {
      return 'Minute must be 0-59';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Remind Me In:'),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hourController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Hour (0-23)',
                        border: const OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(15.0),
                          ),
                        ),
                        errorText: _hourError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _hourError = _validateHour(value);
                          if (_hourError == null && value.isNotEmpty) {
                            selectedTime = TimeOfDay(
                              hour: int.parse(value),
                              minute: selectedTime.minute,
                            );
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _minuteController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Hour (0-59)',
                        border: const OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(15.0),
                          ),
                        ),
                        errorText: _minuteError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _minuteError = _validateMinute(value);
                          if (_minuteError == null && value.isNotEmpty) {
                            selectedTime = TimeOfDay(
                              hour: selectedTime.hour,
                              minute: int.parse(value),
                            );
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                final hourError =_validateHour(_hourController.text);
                final minuteError= _validateMinute(_minuteController.text);
                setState(() {
                  _hourError = hourError;
                  _minuteError = minuteError;
                });
                if (hourError != null || minuteError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid time')),
                  );
                  return;
                }
                try {

                  // Ensure initialization before showing notification
                  await notiService.init();
                  await notiService.scheduleNotification(
                    title: 'TIME TO PLAY',
                    body: 'YOU HAVE A NEW NOTIFICATION',
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Notification Scheduled! for ${selectedTime.format(context)}!',
                      ),
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

              child: const Text(
                'Send Notification Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
