import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/youtube/v3.dart' as yt;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      yt.YouTubeApi.youtubeScope,
      yt.YouTubeApi.youtubeUploadScope,
    ],
  );
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  //Getting Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Reset Password
  Future<void> sendPasswordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //Sign In With Email and Password
  Future<UserCredential> signInwithEmailPassword(String email, password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Sign Up with Email and Password
  Future<UserCredential> signUpwithEmailPassword(String email, password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      });
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  /// Sign In With Google
  signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      // If user cancels the sign-in process
      if (gUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create a new credential
      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        authCredential,
      );

      await firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': gUser.email,
      }, SetOptions(merge: true)); // this prevent overwriting existing data
      // Sign in to Firebase with the Google credential
      return {
        'userCredential': userCredential,
        'accessToken': gAuth.accessToken,
      };
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } on PlatformException catch (e) {
      print('Platform Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('General Error: $e');
      return null;
    }
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Phone Auth
}
