import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
      'Seat Number': seatNumber,
    };

    await firestore.collection('Users').doc(userId).set({
      'Vehicle Details': vehicleDetails,
    }, SetOptions(merge: true));
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
