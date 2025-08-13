import 'package:flutter/material.dart';
class MessagePage extends StatelessWidget {
  final String receiverEmail;
  const MessagePage({super.key, required this.receiverEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(receiverEmail),),
    );
  }
}
