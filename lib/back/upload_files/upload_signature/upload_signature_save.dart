import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/upload_files/upload_signature/signature_post_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<void> uploadSignatureAndSave(
  Uint8List signBytes,
  BuildContext context,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userID = user.uid;
  final storageRef = FirebaseStorage.instance.ref();
  final firestore = FirebaseFirestore.instance;
  final filePath =
      'Users/$userID/Signature/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final fileRef = storageRef.child(filePath);

  UploadTask uploadTask = fileRef.putData(signBytes);
  TaskSnapshot taskSnapshot = await uploadTask;
  String signatureUrl = await taskSnapshot.ref.getDownloadURL();
  Timestamp date = Timestamp.fromDate(DateTime.now());
  await firestore.collection('Users').doc(userID).set({
    'signatureUrl': signatureUrl,
    'Contract Signing': 'SIGNED',
    'Tour end Date': date,
  }, SetOptions(merge: true));
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;
  final currentUserEmail = currentUser.email;
  if (currentUserEmail != null) {
    final SignaturePostApi signaturePostApi = SignaturePostApi();
    final success = await signaturePostApi.postData({
      'image': signatureUrl,
      'user': currentUserEmail,
    });

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Data posted successfully!")));
      }
    }
  }
}
