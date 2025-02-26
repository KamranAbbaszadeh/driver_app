import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<List<File>?> mediaFilePicker() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    withData: true,
    allowMultiple: true,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
    type: FileType.custom,
    allowCompression: true,
  );
  if (result != null) {
    PlatformFile doc = result.files.first;
    List<File> files = result.paths.map((path) => File(doc.path!)).toList();

    return files;
  }
  return null;
}
