import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<void> pickImage({
    required BuildContext context,
    required Function(List<XFile>) onPicked,
    bool allowCamera = true,
    bool allowGallery = true,
  }) async {
    final granted = await _requestPermissions(camera: allowCamera);
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions are required to access images'),
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      final width = MediaQuery.of(context).size.width;
      final height = MediaQuery.of(context).size.height;
      final darkMode =
          MediaQuery.of(context).platformBrightness == Brightness.dark;
      await showModalBottomSheet(
        context: context,
        backgroundColor:
            darkMode
                ? const Color.fromARGB(255, 61, 61, 61)
                : const Color.fromARGB(255, 224, 221, 221),
        constraints: BoxConstraints(minWidth: width),
        builder:
            (ctx) => SafeArea(
              child: Padding(
                padding: EdgeInsets.all(width * 0.04),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: height * 0.01,
                  children: [
                    if (allowGallery)
                      GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          List<XFile> images = await _picker
                              .pickImage(source: ImageSource.gallery)
                              .then((img) => img != null ? [img] : []);
                          if (images.isNotEmpty) onPicked(images);
                        },
                        child: Row(
                          spacing: width * 0.02,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: darkMode ? Colors.white : Colors.black,
                            ),
                            Text(
                              'Pick from Gallery',
                              style: GoogleFonts.cabin(
                                color: darkMode ? Colors.white : Colors.black,
                                fontSize: width * 0.045,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (allowCamera)
                      GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          final image = await _picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (image != null) onPicked([image]);
                        },
                        child: Row(
                          spacing: width * 0.02,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: darkMode ? Colors.white : Colors.black,
                            ),
                            Text(
                              'Take Photo',
                              style: GoogleFonts.cabin(
                                color: darkMode ? Colors.white : Colors.black,
                                fontSize: width * 0.045,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      );
    }
  }

  static Future<XFile?> selectSinglePhoto({
    required BuildContext context,
  }) async {
    final selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected == null) return null;
    return selected;
  }

  static Future<List<XFile>?> selectMultiplePhotos({
    required BuildContext context,
  }) async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo permission denied')),
        );
      }
      return null;
    }

    final images = await _picker.pickMultiImage();
    if (images.isEmpty) return null;
    return images;
  }

  static Future<bool> _requestPermissions({required bool camera}) async {
    final galleryStatus = await Permission.photos.request();
    final cameraStatus =
        camera ? await Permission.camera.request() : PermissionStatus.granted;
    return galleryStatus.isGranted && cameraStatus.isGranted;
  }
}

class ImageGrid extends StatefulWidget {
  final List<XFile> images;
  final void Function(int index)? onRemove;

  const ImageGrid({super.key, required this.images, required this.onRemove});

  @override
  State<ImageGrid> createState() => _ImageGridState();
}

class _ImageGridState extends State<ImageGrid> {
  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final images = widget.images;
    return GridView.builder(
      itemCount: images.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(width * 0.02),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: width * 0.02,
        mainAxisSpacing: width * 0.02,
      ),
      itemBuilder: (_, index) {
        final image = images[index];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width * 0.01),
                child: Image.file(File(image.path), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: -height * 0.009,
              right: -width * 0.02,
              child: GestureDetector(
                onTap: () {
                  if (widget.onRemove != null) {
                    widget.onRemove!(index);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.cancel,
                    color:
                        darkMode
                            ? Color.fromARGB(255, 1, 105, 170)
                            : Color.fromARGB(255, 52, 168, 235),
                    size: width * 0.05,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
