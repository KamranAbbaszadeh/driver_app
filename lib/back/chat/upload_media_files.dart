import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart'; // To check MIME type

Future<String> uploadMediaFile({
  required Reference storageRef,
  required String userID,
  required dynamic file,
  required String folderName,
  required String tourId,
}) async {
  final mimeType = lookupMimeType(file.path);

  String fileExtension = '.jpg';
  if (mimeType != null) {
    if (mimeType.startsWith('image')) {
      fileExtension = '.jpg';
    } else if (mimeType.startsWith('video')) {
      fileExtension = '.mp4';
    }
  }

  final filePath =
      'Users/$userID/$folderName/${DateTime.now().millisecondsSinceEpoch}$fileExtension';
  final fileRef = storageRef.child(filePath);

  UploadTask uploadTask = fileRef.putData(await file.readAsBytes());

  TaskSnapshot taskSnapshot = await uploadTask;
  return await taskSnapshot.ref.getDownloadURL();
}
