import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/upload_files/vehicle_details/vehicle_details_post_api.dart';
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

  // Check if car with same Vehicle Registration Number already exists
  String? existingVehicleId;
  for (final doc in vehiclesSnapshot.docs) {
    final data = doc.data();
    final existingRegNumber = data['Vehicle Registration Number'] ?? '';
    if (existingRegNumber == vehicleDetails['Vehicle Registration Number']) {
      existingVehicleId = doc.id;
      break;
    }
  }

  String vehicleId;
  if (existingVehicleId != null) {
    // Update existing car
    await vehiclesCollection
        .doc(existingVehicleId)
        .set(vehicleDetails, SetOptions(merge: true));
    vehicleId = existingVehicleId;
    logger.i('Updated existing vehicle: $vehicleId');
  } else {
    // Create new car
    int lastId = existingIds.where((id) => id.startsWith('Car')).fold<int>(0, (
      prev,
      id,
    ) {
      final number = int.tryParse(id.replaceFirst('Car', '')) ?? 0;
      return number > prev ? number : prev;
    });

    lastId += 1;
    String newVehicleId = 'Car$lastId';

    await vehiclesCollection
        .doc(newVehicleId)
        .set(vehicleDetails, SetOptions(merge: true));
    vehicleId = newVehicleId;
    logger.i('Created new vehicle: $vehicleId');
  }

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

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;
  final currentUserEmail = currentUser.email;

  if (currentUserEmail != null) {
    final VehicleDetailsPostApi vehicleDetailsPostApi = VehicleDetailsPostApi();
    Map<String, dynamic> vehicleDetailsforPos = {
      "image": vehicleDetails['Vehicle Photos'],
      "CarName": vehicleDetails['Vehicle Name'],
      "TechnicalPassport": vehicleDetails['Technical Passport Number'],
      "Year": vehicleDetails['Vehicle\'s Year'],
      "Category": vehicleDetails['Vehicle\'s Type'],
      "SeatNumber": vehicleDetails['Seat Number'],
      "User": currentUserEmail,
      "VehicleRegistrationNumber":
          vehicleDetails['Vehicle Registration Number'],
      "TechnicalPassportImages": vehicleDetails['Technical Passport Photos'],
      "ChasisNumber": vehicleDetails['Chassis Number'],
      "ChasisNumberImage": vehicleDetails['Chassis Number Photo'],
      "DocName": vehicleId,
    };
    final success = await vehicleDetailsPostApi.postData(vehicleDetailsforPos);
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
    if (path.isNotEmpty && !path.startsWith('https://')) {
      final file = File(path);
      if (file.existsSync()) {
        final uploadRef = storageRef
            .child(vehicleRegisterNum)
            .child(folderName)
            .child('${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = await uploadRef.putFile(file);
        final url = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(url);
      }
    } else if (path.startsWith('https://')) {
      uploadedUrls.add(path);
    }
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
  if (path.isNotEmpty && !path.startsWith('https://')) {
    final file = File(path);
    if (file.existsSync()) {
      final uploadRef = storageRef
          .child(vehicleRegisterNum)
          .child(folderName)
          .child('${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await uploadRef.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } else {
      return '';
    }
  } else if (path.startsWith('https://')) {
    return path;
  } else {
    return '';
  }
}
