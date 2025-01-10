import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> uploadSignatureAndSave(Uint8List signBytes) async {
  final userID = FirebaseAuth.instance.currentUser?.uid;
  final storageRef = FirebaseStorage.instance.ref();
  final firestore = FirebaseFirestore.instance;
  final filePath =
      'Users/$userID/Signature/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final fileRef = storageRef.child(filePath);

  UploadTask uploadTask = fileRef.putData(signBytes);
  TaskSnapshot taskSnapshot = await uploadTask;
  String signatureUrl = await taskSnapshot.ref.getDownloadURL();
  await firestore.collection('Users').doc(userID).set({
    'signatureUrl': signatureUrl,
  }, SetOptions(merge: true));
}
