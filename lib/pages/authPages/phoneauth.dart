import 'package:chessgame/component/button.dart';
import 'package:chessgame/component/textfield.dart';
import 'package:chessgame/pages/authPages/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneAuth extends StatelessWidget {
  PhoneAuth({super.key});
  TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phone Auth')),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyTextField(
              hint: 'Enter Phone Number',
              controller: phoneController,
              obscureText: false,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String number = phoneController.text.trim();

                try {
                  await FirebaseAuth.instance.verifyPhoneNumber(
                    verificationCompleted: (PhoneAuthCredential credential) {},
                    verificationFailed: (FirebaseAuthException ex) {},
                    codeSent: (String verificationId, int? resendToken) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OtpScreen(verificationId: verificationId),
                        ),
                      );
                    },
                    codeAutoRetrievalTimeout: (String verificationId) {},
                    phoneNumber: "+977$number",
                  );
                } catch (e) {
                  throw Exception(e);
                }
              },
              child: Text('Verify Phone Number'),
            ),
          ],
        ),
      ),
    );
  }
}
