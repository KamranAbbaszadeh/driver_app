// Uploads user certificate files to Firebase Storage and Firestore, and sends metadata to an external API.
// Handles multiple certificate types, retrieves download URLs, and ensures existing file links are reused.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/upload_files/certificates/certificate_post_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
/// Uploads the provided list of [certificates] to Firebase Storage and saves metadata in Firestore.
/// If the certificate is already uploaded (valid URL), it reuses the link instead of uploading again.
/// Also sends certificate data to an external API endpoint for registration.
/// Displays a success message if the API post is successful.
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

      dynamic file = certificates[i]['file'];
      if (file == null) {
        continue;
      }

      final filePath = file is File ? file.path : file;
      String fileUrl = '';

      if (filePath != null &&
          filePath is String &&
          filePath.isNotEmpty &&
          !filePath.startsWith('https://')) {
        await storageRef.putFile(File(filePath));
        fileUrl = await storageRef.getDownloadURL();
      } else if (file is String && file.startsWith('https://')) {
        fileUrl = file;
      } else if (file is XFile && file.path.startsWith('https://')) {
        fileUrl = file.path;
      } else {
        fileUrl = '';
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final currentUserEmail = user.email;

      Map<String, String> certificateData = {
        'name': certificates[i]['name'] as String,
        'type': certificates[i]['type'] as String,
        'doc': fileUrl,
        'fileName': certificates[i]['file name'] as String,
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
    try {
      await FirebaseFirestore.instance.collection('Users').doc(userId).set({
        'certificates': certificatesMap,
      }, SetOptions(merge: true));
      logger.d(certificatesMap);
    } on Exception catch (e) {
      logger.e(e);
    }
    final CertificatePostApi certificatePostApi = CertificatePostApi();
    await certificatePostApi.postData({
      "certificates": certificatesPostMap,
    });
    
  }
}
