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

class ImageGrid extends StatelessWidget {
  final List<XFile> images;
  final void Function(int index) onRemove;
  final bool isDeclined;

  const ImageGrid({
    super.key,
    required this.images,
    required this.onRemove,
    required this.isDeclined,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return GridView.builder(
      itemCount: images.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: width * 0.02,
        crossAxisSpacing: width * 0.02,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final image = images[index];

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDeclined ? Colors.redAccent : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    image.path.startsWith('https://')
                        ? Image.network(
                          image.path,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                        : Image.file(
                          File(image.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
