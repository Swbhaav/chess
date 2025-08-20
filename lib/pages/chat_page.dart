import 'package:chessgame/component/user_tile.dart';
import 'package:chessgame/pages/message_page.dart';
import 'package:chessgame/services/auth/auth_service.dart';
import 'package:chessgame/services/chat/chatService.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  ChatPage({super.key});
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildUserList());
  }

  Widget _buildUserList() {

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat With Other"),
        centerTitle: true,

      ),
      body: StreamBuilder(
        stream: _chatService.getUserStream(),
        builder: (context, snapshot) {
          // error
          if (snapshot.hasError) {
            return const Text('Error');
          }
          //Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          //return ListView
          return ListView(
            children: snapshot.data!
                .map<Widget>((userData) => _buildUserListItem(userData, context))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    //display all user except current user
    if(userData["email"] != _authService.getCurrentUser()!.email){
      return UserTile(
        text: userData["email"],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagePage(receiverEmail: userData['email'], receiverID: userData['uid'],),
            ),
          );
        },
      );
    }else{
      return Container(

      );
    }
  }
}
