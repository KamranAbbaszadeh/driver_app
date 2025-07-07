// Handles media file uploads to Firebase Storage.
// Determines file type (image/video), sets correct file extension, uploads to a structured path,
// and returns the downloadable URL of the uploaded file.
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';

/// Uploads a media file (image or video) to Firebase Storage.
/// Automatically determines the file type and extension.
/// Stores the file under the structure: Users/{userID}/{folderName}/{timestamp}.{ext}
/// Returns the download URL after successful upload.
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
