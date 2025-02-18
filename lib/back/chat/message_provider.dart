import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

class MessageProvider extends ChangeNotifier {
  final String tourId;
  MessageProvider({required this.tourId});

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String message) async {
    final user = _firebaseAuth.currentUser;
    DocumentReference docRefReceiver = _firestore
        .collection('Chat')
        .doc(user!.uid)
        .collection(tourId)
        .doc('receiver');

    DocumentSnapshot docSnapshot = await docRefReceiver.get();
    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      int nextIndex = 1;
      while (data.containsKey('message$nextIndex')) {
        nextIndex++;
      }
      await docRefReceiver.update({
        'message$nextIndex': {
          'message': message,
          'createdAt': Timestamp.now(),
          'isRead': false,
        },
      });
    } else {
      await docRefReceiver.update({
        'message1': {
          'message': message,
          'createdAt': Timestamp.now(),
          'isRead': false,
        },
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages() {
    final user = _firebaseAuth.currentUser;
    // if (user == null) return const Stream.empty();

    DocumentReference docRefReceiver = _firestore
        .collection('Chat')
        .doc(user!.uid)
        .collection(tourId)
        .doc('receiver');

    DocumentReference docRefSender = _firestore
        .collection('Chat')
        .doc(user.uid)
        .collection(tourId)
        .doc('sender');

    return Rx.combineLatest2(
      docRefReceiver.snapshots(),
      docRefSender.snapshots(),
      (DocumentSnapshot receiverSnapshot, DocumentSnapshot senderSnapshot) {
        List<Map<String, dynamic>> messages = [];
        bool hasUnreadMessage = false;

        if (receiverSnapshot.exists) {
          Map<String, dynamic> data =
              receiverSnapshot.data() as Map<String, dynamic>;
          data.forEach((key, value) {
            if (key.startsWith('message')) {
              messages.add({
                'message': value['message'],
                'createdAt': value['createdAt'],
                'isRead': value['isRead'],
                'isMe': true,
              });
            }
          });
        }

        if (senderSnapshot.exists) {
          Map<String, dynamic> data =
              senderSnapshot.data() as Map<String, dynamic>;
          data.forEach((key, value) {
            bool isRead = value['isRead'] ?? false;
            if (key.startsWith('message')) {
              messages.add({
                'message': value['message'],
                'createdAt': value['createdAt'],
                'position': value['position'],
                'name': value['name'],
                'isMe': false,
                'hasUnreadMessage': !isRead,
              });
              if (!isRead) {
                hasUnreadMessage = true;
              }
            }
          });
        }

        if (hasUnreadMessage) {
         
        }

        messages.sort(
          (a, b) => (a['createdAt'] as Timestamp).compareTo(
            b['createdAt'] as Timestamp,
          ),
        );

        return messages;
      },
    );
  }

 
}
