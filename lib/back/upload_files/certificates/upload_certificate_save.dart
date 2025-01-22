import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/upload_files/certificates/certificate_post_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<void> uploadCertificateAndSave({
  required String userId,
  required List<Map<String, dynamic>> certificates,
  required context,
}) async {
  if (certificates.isNotEmpty) {
    Map<String, Map<String, String>> certificatesMap = {};
    List<Map<String, String>> certificatesPostMap = [];
    for (int i = 0; i < certificates.length; i++) {
      final fileName = certificates[i]['name'];
      final folderName = certificates[i]['type'];

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference storageRef = storage.ref().child(
        'Users/$userId/certificates/$folderName/$fileName',
      );

      await storageRef.putFile(certificates[i]['file']);
      String fileUrl = await storageRef.getDownloadURL();

      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

      Map<String, String> certificateData = {
        'name': certificates[i]['name'] as String,
        'type': certificates[i]['type'] as String,
        'image': fileUrl,
      };

      if (currentUserEmail != null) {
        Map<String, String> certificateDataPost = {
          'name': certificates[i]['name'] as String,
          'type': certificates[i]['type'] as String,
          'email': currentUserEmail,
          'image': fileUrl,
        };

        certificatesPostMap.add(certificateDataPost);

        certificatesMap[fileName] = certificateData;
      }
    }
    await FirebaseFirestore.instance.collection('Users').doc(userId).set({
      'certificates': certificatesMap,
    }, SetOptions(merge: true));
    final CertificatePostApi certificatePostApi = CertificatePostApi();
    final success = await certificatePostApi.postData({
      "certificates": certificatesPostMap,
    });
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Data posted successfully!")));
    }
  }
}
