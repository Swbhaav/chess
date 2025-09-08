import 'package:chessgame/component/message_model.dart';
import 'package:chessgame/services/chat/chathead_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatRoomID(String userID1, String userID2) {
    List<String> ids = [userID1, userID2];
    ids.sort();
    return ids.join('_');
  }

  //get user Stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        //go through each individual user
        final user = doc.data();

        //return user
        return user;
      }).toList();
    });
  }

  //Send message
  Future<void> sendMessage(String receiverID, message) async {
    //get current user info
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    //Create a new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the 2 user (sorted to ensure uniqueness)
    List<String> ids = [currentUserID, receiverID];
    ids.sort(); //sort the ids (this ensure the chatroomID is the same for any 2 people)
    String chatRoomID = ids.join('_');

    // add new message to database
    await _firestore
        .collection("chat_room")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());

    _triggerChatHeadForReceiver(receiverID, message, chatRoomID);
  }

  Future<void> _triggerChatHeadForReceiver(
    String receiverID,
    String message,
    String chatRoomID,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final receiverDoc = await _firestore
          .collection('Users')
          .doc(receiverID)
          .get();
      if (!receiverDoc.exists) return;

      final receiverData = receiverDoc.data() as Map<String, dynamic>;

      final bool isReceiverOnline = receiverData['isOnline'] ?? false;

      if (!isReceiverOnline) {
        final chatHeadService = ChatHeadService();

        await chatHeadService.showChatHeadForMessage(
          senderName: currentUser.email!.split('@')[0],
          message: message,
          chatRoomId: chatRoomID,
          unreadCount: 1,
          senderAvatar: receiverData['avatarUrl'],
        );
      }
    } catch (e) {
      print('Error triggering chat head: $e');
    }
  }

  // get messages
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    //construct a chatroom ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');
    return _firestore
        .collection("chat_room")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  Future<void> updateActiveStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore.collection('Users').doc(user.uid).update({'isOnline': isOnline});
  }

  Stream<Map<String, dynamic>> getUserStatusStream(String userID) {
    return _firestore.collection('Users').doc(userID).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return {'isOnline': data['isOnline'] ?? false};
      }
      return {'isOnline': false};
    });
  }

  Future<Map<String, dynamic>> getUserInfo(String userID) async {
    try {
      final doc = await _firestore.collection('Users').doc(userID).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error getting user info: $e');
      return {};
    }
  }

  Future<void> clearUnreadCount(String chatRoomID) async {
    try {
      final chatHeadService = ChatHeadService();
      await chatHeadService.clearUnreadCount(chatRoomID);
    } catch (e) {
      print('Error clearing unread count: $e');
    }
  }

  Future<bool> isChatHeadActive() async {
    try {
      final chatHeadService = ChatHeadService();
      return await chatHeadService.isOverlayActive;
    } catch (e) {
      print('Error checking chat head status: $e');
      return false;
    }
  }
}
