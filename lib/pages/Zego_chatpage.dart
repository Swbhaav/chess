import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

class ZimChatList extends StatelessWidget {
  const ZimChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Conversation')),
        body: ZIMKitConversationListView(
          onPressed: (context, conversation, defaultAction) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ZIMKitMessageListPage(
                    conversationID: conversation.id,
                    conversationType: conversation.type,
                  );
                },
              ),
            );
          },
        ),
      ),
      onWillPop: () async => false,
    );
  }
}
