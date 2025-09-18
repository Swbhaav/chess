import 'package:chessgame/services/notification/enhanced_noti_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/youtube/v3.dart' as yt;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      yt.YouTubeApi.youtubeScope,
      yt.YouTubeApi.youtubeUploadScope,
    ],
  );
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  EnhancedNotificationService notificationService =
      EnhancedNotificationService();

  Future<String> getCurrentUserStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'offline';

      final doc = await _firestore.collection('Users').doc(user.uid).get();
      return doc.data()?['status'] ?? 'offline';
    } catch (e) {
      print('Error Getting status: $e');
      return 'offline';
    }
  }

  Future<String> getUserStatus(String userId) async {
    try {
      final doc = await _firestore.collection('Users').doc(userId).get();
      return doc.data()?['status'] ?? 'offline';
    } catch (e) {
      print('Error getting use status: $e');
      return 'offline';
    }
  }

  Future<void> updateUserStatus(String status) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).update({
          'status': status,
        });
      }
    } catch (e) {
      print('Error updating status: $e');
    }
  }

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

      await _initializeNotificationForUser(userCredential.user!.uid);

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
        'status': "Unavalible",
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });

      await _initializeNotificationForUser(userCredential.user!.uid);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String? deviceToken = await EnhancedNotificationService.getToken();
        if (deviceToken != null) {
          await EnhancedNotificationService.deactivateToken(
            user.uid,
            deviceToken,
          );
        }

        await updateUserStatus('offline');
      }
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      print('Error during sign out: $e');
      await _auth.signOut();
    }
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
        'status': "Unavalible",
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
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
      final user = _auth.currentUser;
      if (user != null) {
        String? deviceToken = await EnhancedNotificationService.getToken();
        if (deviceToken != null) {
          await EnhancedNotificationService.deactivateToken(
            user.uid,
            deviceToken,
          );
        }
        await _firestore.collection('Users').doc(user.uid).delete();
        await user.delete();
      }
    } catch (e) {
      print('Error deleting account: $e');
      throw Exception(e);
    }
  }

  Future<void> _initializeNotificationForUser(String userId) async {
    try {
      print('Initializing notification for user: $userId');

      await EnhancedNotificationService.initialize(
        userId: userId,
        onChatNotificationTap: (data) {
          print('Notification tapped with data: $data');
        },
      );

      print('Notification service initialized successfully for user: $userId');
    } catch (e) {
      print('Error initiailizing notification service: $e');
    }
  }

  Future<void> registerUserForNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return;
      }

      await _initializeNotificationForUser(user.uid);
    } catch (e) {
      print('Error registering user for notifications: $e');
    }
  }

  Future<void> updateUserTargeting({
    String? location,
    Map<String, String>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? deviceToken = await EnhancedNotificationService.getToken();
      if (deviceToken == null) return;

      await EnhancedNotificationService.updateUserTargeting(
        userId: user.uid,
        deviceToken: deviceToken,
        location: location,
        metadata: metadata,
      );

      print('User targeting updated successfully');
    } catch (e) {
      print('Error updating user targeting: $e');
    }
  }

  Future<bool> hasValidNotificationToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      String? token = await EnhancedNotificationService.getTokenFromFirestore(
        user.uid,
      );
      return token != null;
    } catch (e) {
      print('Error checking notification token: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserNotificationInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await EnhancedNotificationService.getUserInfo(user.uid);
    } catch (e) {
      print('Error getting user notification info: $e');
      return null;
    }
  }
}
