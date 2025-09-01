import 'package:chessgame/pages/authPages/phoneauth.dart';
import 'package:chessgame/pages/authPages/register.dart';
import 'package:chessgame/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../component/button.dart';
import '../../component/textfield.dart';
import '../../services/auth/auth_service.dart';
import 'forget_password.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  final authService = AuthService();

  LoginPage({super.key});

  void login(BuildContext context) async {
    // Form is first validated
    if (_formkey.currentState!.validate()) {
      // Checking if password is matching

      try {
        await authService.signInwithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logged in Successfully')));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Login Error'),
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  void loginWithGoogle(BuildContext context) async {
    try {
      await authService.signInWithGoogle();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Error'),
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Center(
              child: Text(
                'Welcome to Login page',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ),
          ),

          Form(
            key: _formkey,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  MyTextField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      return null;
                    },
                    controller: _emailController,
                    obscureText: false,
                    hint: 'Email',
                    prefixIcon: Icons.email_rounded,
                  ),
                  MyTextField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                    controller: _passwordController,
                    obscureText: true,
                    hint: 'Password',
                    prefixIcon: Icons.password_sharp,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgetPassword(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: MyButton(
                      text: 'Login',
                      onTap: () => login(context),
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: MyButton(
                            text: 'Login with Google',
                            onTap: () => loginWithGoogle(context),
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: MyButton(
                            text: 'Login with OTP',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PhoneAuth(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Do not have account,"),
                      SizedBox(width: 5),

                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
