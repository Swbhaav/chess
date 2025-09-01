import 'package:chessgame/component/textfield.dart';
import 'package:chessgame/pages/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  String verificationId;
  OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  TextEditingController otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OTP Screen')),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            MyTextField(
              hint: 'Enter OTP',
              controller: otpController,
              obscureText: false,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                try {
                  PhoneAuthCredential credential =
                      await PhoneAuthProvider.credential(
                        verificationId: widget.verificationId,
                        smsCode: otpController.text.toString(),
                      );
                  FirebaseAuth.instance.signInWithCredential(credential).then((
                    value,
                  ) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  });
                } catch (ex) {
                  throw Exception(ex);
                }
              },
              child: Text('OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
