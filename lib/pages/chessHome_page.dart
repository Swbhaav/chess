import 'package:chessgame/game_board.dart';
import 'package:chessgame/playWithAI.dart';
import 'package:flutter/material.dart';

import '../component/button.dart';
import '../services/auth/auth_service.dart';
import 'authPages/login.dart';
import 'authPages/register.dart';

class ChessHomePage extends StatelessWidget {
  const ChessHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    AuthService _authService = AuthService();
    void logout(BuildContext context) async {
      try {
        await _authService.signOut();

        // Navigate to login page after successful sign out
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false, // Remove all previous routes
        );
      } catch (e) {
        // Show error message if sign out fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    void delete(BuildContext context) async {
      try {
        await _authService.deleteAccount();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => RegisterPage()),
          (route) => false, // Remove all previous routes
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Account Deleted Successfully')));
      } catch (e) {
        throw Exception(e);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chess Game'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => delete(context),
            icon: Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: MyButton(
                  text: 'Play with Player',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GameBoard()),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: MyButton(
                  text: 'Play with AI',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlayWithAI()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
