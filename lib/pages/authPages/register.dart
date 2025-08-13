import 'package:chessgame/pages/authPages/login.dart';
import 'package:chessgame/pages/homepage.dart';
import 'package:flutter/material.dart';


import '../../component/button.dart';
import '../../component/textfield.dart';
import '../../game_board.dart';
import '../../services/auth/auth_service.dart';


class RegisterPage extends StatelessWidget {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  RegisterPage({super.key});

  void register(BuildContext context) async {
    final authService = AuthService();

    // Form is first validated
    if (_formkey.currentState!.validate()) {
      // Checking if password is matching
      if (_passwordController.text == _confirmPwController.text) {
        try {
          await authService.signUpwithEmailPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registered Successfully')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } catch (e) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Registration Error'),
              content: Text(e.toString()),
            ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Passwords do not match'),
            content: Text('Please make sure both password fields match.'),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Center(
                  child: Text(
                    'Welcome to Register page',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                        validator: (value){
                          if(value== null || value.isEmpty){
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
                        validator: (value){
                          if(value== null || value.isEmpty){
                            return 'Please enter password';
                          }
                          return null;
                        },
                        controller: _passwordController ,
                        obscureText: true,
                        hint: 'Password',
                        prefixIcon: Icons.password_sharp,
                      ),
                      MyTextField(
                        validator: (value){
                          if(value== null || value.isEmpty){
                            return 'Please enter password';
                          }
                          return null;
                        },
                        controller: _confirmPwController,
                        obscureText: true,
                        hint: 'Confirm Password',
                        prefixIcon: Icons.password_sharp,
                      ),
                      SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already Registered,"),
                          SizedBox(width: 5),

                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>LoginPage() ,
                                ),
                              );
                            },
                            child: Text(
                              'Login',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),

                      MyButton(text: 'Register', onTap: () => register(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
