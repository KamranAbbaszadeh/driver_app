// Service class responsible for sending and retrieving chat messages related to a specific tour.
// Integrates Firestore, Firebase Auth, and an external message API.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/chat/message_model.dart';
import 'package:onemoretour/back/chat/message_send_api.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provides chat functionalities for tours, including sending messages with metadata
/// and listening to message updates in real-time from Firestore.
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sends a new chat message for the specified tour.
  /// Stores message in Firestore and posts to an external message API.
  /// Automatically assigns sequential message IDs.
  Future<void> sendMessage({
    required dynamic message,
    required String tourID,
    required String currentUserId,
  }) async {
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

    // Retrieve existing message indexes to calculate the next sequential message ID.
    QuerySnapshot querySnapshot = await docRef.get();
    final existingIndexes =
        querySnapshot.docs
            .where((doc) => doc.id.startsWith('message'))
            .map((doc) {
              final match = RegExp(r'message(\d+)').firstMatch(doc.id);
              return match != null ? int.tryParse(match.group(1)!) : null;
            })
            .whereType<int>()
            .toList()
          ..sort();
    final int nextIndex =
        (existingIndexes.isNotEmpty ? existingIndexes.last + 1 : 1);

    // Send message to external API and store it in Firestore if successful.
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

  /// Returns a stream of chat messages for a given tour.
  /// Messages are ordered by creation time and include the Firestore document ID.
  Stream<List<Map<String, dynamic>>> getMessages({required String tourID}) {
    final String currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('Chat')
        .doc(currentUserId)
        .collection(tourID)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                return {...data, 'docId': doc.id};
              }).toList(),
        );
  }
}
