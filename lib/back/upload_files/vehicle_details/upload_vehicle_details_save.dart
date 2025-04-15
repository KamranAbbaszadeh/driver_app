import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/upload_files/vehicle_details/vehicle_details_post_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<void> uploadVehicleDetailsAndSave({
  required String userId,
  required Map<String, dynamic> vehicleDetails,
  required context,
}) async {
  final firestore = FirebaseFirestore.instance;
  await firestore.collection('Users').doc(userId).set({
    'Vehicle Details': vehicleDetails,
  }, SetOptions(merge: true));

  final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  if (currentUserEmail != null) {
    final VehicleDetailsPostApi vehicleDetailsPostApi = VehicleDetailsPostApi();
    final success = await vehicleDetailsPostApi.postData(vehicleDetails);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Data posted successfully!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Data not posted!")));
    }
  }
}

Future<String> uploadSinglePhoto({
  required Reference storageRef,
  required String userID,
  required dynamic file,
  required String folderName,
}) async {
  final filePath =
      'Users/$userID/$folderName/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final fileRef = storageRef.child(filePath);

  UploadTask uploadTask = fileRef.putData(
    await await file.readAsBytes().then((data) => data.buffer.asUint8List()),
  );
  TaskSnapshot taskSnapshot = await uploadTask;
  return await taskSnapshot.ref.getDownloadURL();
}

Future<List<String>> uploadMultiplePhotos({
  required Reference storageRef,
  required String userId,
  required List<dynamic> files,
  required String folderName,
}) async {
  List<String> urls = [];
  for (var file in files) {
    String url = await uploadSinglePhoto(
      storageRef: storageRef,
      userID: userId,
      file: file,
      folderName: folderName,
    );
    urls.add(url);
  }
  return urls;
}
