import 'package:chessgame/component/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}
