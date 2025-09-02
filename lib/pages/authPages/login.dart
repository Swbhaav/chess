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
        ).showSnackBar(const SnackBar(content: Text('Logged in Successfully')));

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Center(
                child: Text(
                  'Welcome to Login page',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
              ),
            ),

            Form(
              key: _formkey,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
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
                            prefixIcon: Icons.lock,
                          ),
                        ],
                      ),
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
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ),

                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: MyButton(
                        text: 'Login',
                        onTap: () => login(context),
                        size: 17,
                      ),
                    ),
                    const SizedBox(height: 5),

                    const Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey)),
                          Text(
                            'Or Continue with',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Expanded(child: Divider(color: Colors.grey)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        children: [
                          Expanded(
                            child: MyButton(
                              text: 'Google',
                              onTap: () => loginWithGoogle(context),
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: MyButton(
                              text: 'OTP',
                              size: 17,
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

                    const SizedBox(height: 5),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Do not have account,"),
                        const SizedBox(width: 5),

                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
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
      ),
    );
  }
}
