import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/upload_files/personal_data/photo_post_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<void> uploadPhotosAndSaveData({
  required String userId,
  required dynamic personalPhoto,
  required List<XFile> driverLicensePhotos,
  required List<XFile> idPhotos,
  required dynamic context,
}) async {
  final storageRef = FirebaseStorage.instance.ref();
  final firestore = FirebaseFirestore.instance;
  String personalPhotoUrl = '';
  String licenseUrl1 = '';
  String licenseurl2 = '';
  String idUrl1 = '';
  String idUrl2 = '';

  try {
    final List<Future<void>> uploadTasks = [];

    Future<void> uploadPersonal() async {
      if (personalPhoto != null) {
        personalPhotoUrl = await uploadSinglePhoto(
          storageRef: storageRef,
          userID: userId,
          file: personalPhoto,
          folderName: 'personalPhoto',
        );
      }
    }

    Future<void> uploadIDs() async {
      if (idPhotos.isNotEmpty) {
        List<String> idPhotoUrls = await uploadMultiplePhotos(
          storageRef: storageRef,
          userId: userId,
          files: idPhotos,
          folderName: 'idPhotos',
        );
        idUrl1 = idPhotoUrls.isNotEmpty ? idPhotoUrls[0] : '';
        idUrl2 = idPhotoUrls.length > 1 ? idPhotoUrls[1] : '';
      }
    }

    Future<void> uploadLicenses() async {
      if (driverLicensePhotos.isNotEmpty) {
        List<String> licensePhotoUrls = await uploadMultiplePhotos(
          storageRef: storageRef,
          userId: userId,
          files: driverLicensePhotos,
          folderName: 'licensePhotos',
        );
        licenseUrl1 = licensePhotoUrls.isNotEmpty ? licensePhotoUrls[0] : '';
        licenseurl2 = licensePhotoUrls.length > 1 ? licensePhotoUrls[1] : '';
      }
    }

    uploadTasks.add(uploadPersonal());
    uploadTasks.add(uploadIDs());
    uploadTasks.add(uploadLicenses());

    await Future.wait(uploadTasks);

    Map<String, dynamic> updateData = {};
    if (personalPhotoUrl.isNotEmpty) {
      updateData['personalPhoto'] = personalPhotoUrl;
    }

    if (idUrl1.isNotEmpty || idUrl2.isNotEmpty) {
      updateData['idPhotos'] = [idUrl1, idUrl2];
    }

    if (licenseUrl1.isNotEmpty || licenseurl2.isNotEmpty) {
      updateData['licensePhotos'] = [licenseUrl1, licenseurl2];
    }

    await firestore
        .collection('Users')
        .doc(userId)
        .set(updateData, SetOptions(merge: true));

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentUserEmail = user.email;
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
  final uuid = Uuid().v4();
  if (file != null &&
      file is XFile &&
      file.path.isNotEmpty &&
      !file.path.startsWith('https://')) {
    final originalBytes = await file.readAsBytes();

    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: 70,
      format: CompressFormat.jpeg,
    );

    final filePath =
        'Users/$userID/$folderName/${DateTime.now().millisecondsSinceEpoch}_$uuid.jpg';
    final fileRef = storageRef.child(filePath);

    UploadTask uploadTask = fileRef.putData(compressedBytes);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  } else if (file is String && file.startsWith('https://')) {
    return file;
  } else if (file is XFile && file.path.startsWith('https://')) {
    return file.path;
  } else {
    return '';
  }
}

Future<List<String>> uploadMultiplePhotos({
  required Reference storageRef,
  required String userId,
  required List<dynamic> files,
  required String folderName,
}) async {
  List<String> urls = [];
  for (var file in files) {
    if (file != null &&
        file is XFile &&
        file.path.isNotEmpty &&
        !file.path.startsWith('https://')) {
      String url = await uploadSinglePhoto(
        storageRef: storageRef,
        userID: userId,
        file: file,
        folderName: folderName,
      );
      urls.add(url);
    } else if (file is String && file.startsWith('https://')) {
      urls.add(file);
    } else if (file is XFile && file.path.startsWith('https://')) {
      urls.add(file.path);
    }
  }
  return urls;
}
