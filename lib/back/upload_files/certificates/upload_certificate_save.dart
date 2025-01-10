import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> uploadCertificateAndSave({
  required String userId,
  required List<Map<String, dynamic>> certificates,
}) async {
  if (certificates.isNotEmpty) {
    Map<String, Map<String, String>> certificatesMap = {};
    for (int i = 0; i < certificates.length; i++) {
      final fileName = certificates[i]['name'];
      final folderName = certificates[i]['type'];

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference storageRef = storage.ref().child(
        'Users/$userId/certificates/$folderName/$fileName',
      );

      await storageRef.putFile(certificates[i]['file']);
      String fileUrl = await storageRef.getDownloadURL();

      Map<String, String> certificateData = {
        'name': certificates[i]['name'] as String,
        'type': certificates[i]['type'] as String,
        'fileUrl': fileUrl,
      };
      certificatesMap[fileName] = certificateData;

      await FirebaseFirestore.instance.collection('Users').doc(userId).set({
        'certificates': certificatesMap,
      }, SetOptions(merge: true));
    }
  }
}
