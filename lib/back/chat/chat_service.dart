import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/chat/message_model.dart';
import 'package:onemoretour/back/chat/message_send_api.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendMessage({required dynamic message, required String tourID}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();
    DocumentSnapshot userSnapshot =
        await _firestore.collection("Users").doc(currentUserId).get();
    Map<String, dynamic> userData =
        userSnapshot.exists ? userSnapshot.data() as Map<String, dynamic> : {};
    final name = userData['First Name'] ?? 'Unknown';
    final position = userData['Role'] ?? 'Unknown';
    Message newMessage = Message(
      userUID: currentUserId,
      createdAt: timestamp,
      isRead: false,
      message: message,
      name: name,
      position: position,
    );
    CollectionReference docRef = _firestore
        .collection('Chat')
        .doc(currentUserId)
        .collection(tourID);

    QuerySnapshot querySnapshot = await docRef.get();
    int nextIndex = querySnapshot.docs.length + 1;

    final MessageSendApi sendMessage = MessageSendApi();
    try {
      await sendMessage.postData({
        "UserID": currentUserId,
        "Message": message,
        "TourID": tourID,
      });
      await docRef.doc('message$nextIndex').set(newMessage.toMap());
    } catch (e) {
      logger.e(e);
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages({required String tourID}) {
    final String currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('Chat')
        .doc(currentUserId)
        .collection(tourID)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'docId': doc.id,
            };
          }).toList());
  }
}
