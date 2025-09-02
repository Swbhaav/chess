import 'package:flutter/material.dart';

import '../../component/button.dart';
import '../../component/textfield.dart';
import '../../services/auth/auth_service.dart';

class ForgetPassword extends StatefulWidget {
  ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final _emailController = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  void resetPassword() async {
    final _authService = AuthService();
    try {
      await _authService.sendPasswordResetLink(_emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password Reset link was sent to you email')),
      );
      Navigator.pop(context);
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forget Password')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Enter your email to reset you password',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          SizedBox(height: 10),
          Form(
            key: _formkey,
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: MyTextField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter Email';
                        }
                        return null;
                      },
                      controller: _emailController,
                      obscureText: false,
                      hint: 'Email',
                      prefixIcon: Icons.email_rounded,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 5,
                    ),
                    child: MyButton(
                      text: 'Reset Password',
                      size: 17,
                      onTap: resetPassword,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
