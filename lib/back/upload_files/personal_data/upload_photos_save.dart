import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/upload_files/personal_data/photo_post_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<void> uploadPhotosAndSaveData({
  required String userId,
  required dynamic personalPhoto,
  required List<XFile> driverLicensePhotos,
  required List<XFile> idPhotos,
  required dynamic context,
}) async {
  final storageRef = FirebaseStorage.instance.ref();
  final firestore = FirebaseFirestore.instance;
  late String personalPhotoUrl;
  late String licenseUrl1;
  late String licenseurl2;
  late String idUrl1;
  late String idUrl2;
  try {
    // Upload Personal Photo
    if (personalPhoto != null) {
      personalPhotoUrl = await uploadSinglePhoto(
        storageRef: storageRef,
        userID: userId,
        file: personalPhoto,
        folderName: 'personalPhoto',
      );
      await firestore.collection('Users').doc(userId).set({
        'personalPhoto': personalPhotoUrl,
      }, SetOptions(merge: true));
    }

    // Upload ID Photos
    if (idPhotos.isNotEmpty) {
      List<String> idPhotoUrls = await uploadMultiplePhotos(
        storageRef: storageRef,
        userId: userId,
        files: idPhotos,
        folderName: 'idPhotos',
      );
      await firestore.collection('Users').doc(userId).set({
        'idPhotos': idPhotoUrls,
      }, SetOptions(merge: true));
      idUrl1 = idPhotoUrls[0];
      idUrl2 = idPhotoUrls[1];
    }

    // Upload Driver License Photos
    if (driverLicensePhotos.isNotEmpty) {
      List<String> licensePhotoUrls = await uploadMultiplePhotos(
        storageRef: storageRef,
        userId: userId,
        files: driverLicensePhotos,
        folderName: 'licensePhotos',
      );
      await firestore.collection('Users').doc(userId).set({
        'licensePhotos': licensePhotoUrls,
      }, SetOptions(merge: true));
      licenseUrl1 = licensePhotoUrls[0];
      licenseurl2 = licensePhotoUrls[1];
    }

    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail != null) {
      try {
        final PhotoPostApi photoPostApi = PhotoPostApi();
        final success = await photoPostApi.postData({
          'User': currentUserEmail,
          'ProfilPhoto': personalPhotoUrl,
          'Licence1': licenseUrl1,
          'Licence2': licenseurl2,
          'ID1': idUrl1,
          'ID2': idUrl2,
        });

        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Data posted successfully!")));
        }
      } catch (e) {
        logger.e('Error posting data: $e');
      }
    } else {
      logger.e('Email is empty');
    }
  } catch (e) {
    logger.e('Error uploading photos: $e');
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
