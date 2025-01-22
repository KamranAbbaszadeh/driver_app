import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/upload_files/vehicle_details/vehicle_details_post_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';

Future<void> uploadVehicleDetailsAndSave({
  required String userId,
  required String carName,
  required List<Asset> vehiclePhoto,
  required String technicalPassportNumber,
  required List<Asset> technicalPassport,
  required String chassisNumber,
  required dynamic chassisPhoto,
  required String vehicleRegistrationNumber,
  required String vehiclesYear,
  required String vehicleType,
  required String seatNumber,
  required context,
}) async {
  if (carName != '' &&
      vehiclePhoto.isNotEmpty &&
      technicalPassportNumber != '' &&
      technicalPassport.isNotEmpty &&
      chassisNumber != '' &&
      chassisPhoto != null &&
      vehicleRegistrationNumber != '' &&
      vehiclesYear != '' &&
      vehicleType != '' &&
      seatNumber != '') {
    final storageRef = FirebaseStorage.instance.ref();
    final firestore = FirebaseFirestore.instance;
    List<String> vehiclePhotosUrls = await uploadMultiplePhotos(
      storageRef: storageRef,
      userId: userId,
      files: vehiclePhoto,
      folderName: 'Vehicle Photos',
    );
    List<String> technicalPassportUrls = await uploadMultiplePhotos(
      storageRef: storageRef,
      userId: userId,
      files: technicalPassport,
      folderName: 'Technical Passport',
    );
    String chassisNumberUrl = await uploadSinglePhoto(
      storageRef: storageRef,
      userID: userId,
      file: chassisPhoto,
      folderName: 'Chassis Number',
    );

    int seatNumberNum = int.parse(seatNumber);

    Map<String, dynamic> vehicleDetails = {
      'Vehicle Name': carName,
      'Vehicle Photos': vehiclePhotosUrls,
      'Technical Passport Number': technicalPassportNumber,
      'Technical Passport Photos': technicalPassportUrls,
      'Chassis Number': chassisNumber,
      'Chassis Number Photo': chassisNumberUrl,
      'Vehicle Registration Number': vehicleRegistrationNumber,
      'Vehicle\'s Year': vehiclesYear,
      'Vehicle\'s Type': vehicleType,
      'Seat Number': seatNumberNum,
    };

    await firestore.collection('Users').doc(userId).set({
      'Vehicle Details': vehicleDetails,
    }, SetOptions(merge: true));

    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    if (currentUserEmail != null) {
      final VehicleDetailsPostApi vehicleDetailsPostApi =
          VehicleDetailsPostApi();
      final success = await vehicleDetailsPostApi.postData({
        'image': vehiclePhotosUrls,
        'CarName': carName,
        'TechnicalPassport': technicalPassportNumber,
        'Year': vehiclesYear,
        'Category': vehicleType,
        'SeatNumber': seatNumberNum,
        'User': currentUserEmail,
        'VehicleRegistrationNumber': vehicleRegistrationNumber,
        'TechnicalPassportImages': technicalPassportUrls,
        'ChasisNumber': chassisNumber,
        'ChasisNumberImage': chassisNumberUrl,
      });
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
    await file.getByteData().then((data) => data.buffer.asUint8List()),
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
