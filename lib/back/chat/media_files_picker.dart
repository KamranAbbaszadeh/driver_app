// Provides a utility function for selecting multiple media files using file picker.
// Supports picking images and videos with specific extensions and returns them as a list of File objects.
import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Prompts the user to pick one or more media files (images or videos).
/// Returns a list of selected [File]s or null if the user cancels.
/// Only allows files with extensions: jpg, jpeg, png, mp4, mov.
Future<List<File>?> mediaFilePicker() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    withData: true,
    allowMultiple: true,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
    type: FileType.custom,
  );
  if (result != null) {
    PlatformFile doc = result.files.first;
    List<File> files = result.paths.map((path) => File(doc.path!)).toList();

    return files;
  }
  return null;
}
