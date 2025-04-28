import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/upload_files/vehicle_details/vehicle_details_post_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<void> uploadVehicleDetailsAndSave({
  required String userId,
  required Map<String, dynamic> vehicleDetails,
  required BuildContext context,
}) async {
  final firestore = FirebaseFirestore.instance;

  final vehiclesCollection = firestore
      .collection('Users')
      .doc(userId)
      .collection('Vehicles');

  final vehiclesSnapshot = await vehiclesCollection.get();

  final existingIds = vehiclesSnapshot.docs.map((doc) => doc.id).toList();
  int lastId = existingIds.where((id) => id.startsWith('Car')).fold<int>(0, (
    prev,
    id,
  ) {
    final number = int.tryParse(id.replaceFirst('Car', '')) ?? 0;
    return number > prev ? number : prev;
  });

  lastId += 1;
  String vehicleId = 'Car$lastId';

  await vehiclesCollection
      .doc(vehicleId)
      .set(vehicleDetails, SetOptions(merge: true));

  final userRef = firestore.collection('Users').doc(userId);
  final userDoc = await userRef.get();
  final currentVehicleTypeString = userDoc.data()?['Vehicle Type'] ?? '';

  final existingVehicleTypes =
      currentVehicleTypeString.isNotEmpty
          ? currentVehicleTypeString.split(',').map((e) => e.trim()).toList()
          : [];

  bool updated = false;
  final newVehicleType = vehicleDetails['Vehicle\'s Type'];

  if (newVehicleType != null && newVehicleType is String) {
    if (!existingVehicleTypes.contains(newVehicleType)) {
      existingVehicleTypes.add(newVehicleType);
      updated = true;
    }
  }

  if (updated) {
    final newVehicleTypeString = existingVehicleTypes.join(', ');
    await userRef.update({'Vehicle Type': newVehicleTypeString});
  }

  final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  if (currentUserEmail != null) {
    final VehicleDetailsPostApi vehicleDetailsPostApi = VehicleDetailsPostApi();
    final success = await vehicleDetailsPostApi.postData(vehicleDetails);
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Data posted successfully!")));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Data not posted!")));
      }
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

Future<List<String>> uploadMultiplePhotosFromPaths(
  List<String> paths,
  Reference storageRef,
  String userId,
  String folderName,
  String vehicleRegisterNum,
) async {
  List<String> uploadedUrls = [];
  for (final path in paths) {
    final file = File(path);
    final uploadRef = storageRef
        .child(vehicleRegisterNum)
        .child(folderName)
        .child('${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = await uploadRef.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();
    uploadedUrls.add(url);
  }
  return uploadedUrls;
}

Future<String> uploadSinglePhotoFromPath(
  String path,
  Reference storageRef,
  String userId,
  String folderName,
  String vehicleRegisterNum,
) async {
  final file = File(path);
  final uploadRef = storageRef
      .child(vehicleRegisterNum)
      .child(folderName)
      .child('${DateTime.now().millisecondsSinceEpoch}');
  final uploadTask = await uploadRef.putFile(file);
  return await uploadTask.ref.getDownloadURL();
}
