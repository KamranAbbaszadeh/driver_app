import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';

final Logger logger = Logger();
Future<void> uploadPhotosAndSaveData({
  required String userId,
  required dynamic personalPhoto,
  required List<Asset> driverLicensePhotos,
  required List<Asset> idPhotos,
}) async {
  final storageRef = FirebaseStorage.instance.ref();
  final firestore = FirebaseFirestore.instance;
  try {
    // Upload Personal Photo
    if (personalPhoto != null) {
      String personalPhotoUrl = await uploadSinglePhoto(
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
