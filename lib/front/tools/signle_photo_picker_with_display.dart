// A widget for picking and displaying a single image with remove functionality.
// Displays a placeholder when no image is selected, and a thumbnail with remove button when an image is picked.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A UI component for single photo selection and preview.
/// If image is selected, shows a 1-image grid with remove icon.
/// Otherwise, shows an icon and instructions for picking a photo.
class SinglePhotoPickerWithDisplay extends StatelessWidget {
  final XFile? image;
  final String label;
  final Future<void> Function() onPick;
  final Future<void> Function() onRemove;
  final bool darkMode;
  final String minPhotos;
  final bool isDeclined;
  final String fieldName;

  const SinglePhotoPickerWithDisplay({
    super.key,
    required this.image,
    required this.label,
    required this.onPick,
    required this.onRemove,
    required this.darkMode,
    required this.minPhotos,
    required this.isDeclined,
    required this.fieldName,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout.
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    // Detect tap anywhere on widget to open image picker.
    return GestureDetector(
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          // Show field label only if an image is already picked.
          labelText: image != null ? fieldName : null,
          filled: true,
          // Set background color based on dark mode.
          fillColor: darkMode ? Colors.grey[900] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(width * 0.04),
          ),
          // Style the border with theme-dependent color.
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(width * 0.04),
            borderSide: BorderSide(
              color: darkMode ? Colors.grey[700]! : Colors.grey[400]!,
            ),
          ),
        ),
        child:
            image == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Placeholder icon for adding a photo.
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: width * 0.1,
                      color: darkMode ? Colors.blue[300] : Colors.blueAccent,
                    ),
                    SizedBox(height: height * 0.005),
                    // Label describing required photo.
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: darkMode ? Colors.blue[100] : Colors.blueGrey,
                      ),
                    ),
                    SizedBox(height: height * 0.005),
                    // Show the required minimum photo count.
                    Text(
                      'Minimum: $minPhotos photo',
                      style: TextStyle(
                        fontSize: height * 0.015,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )
                : GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Display selected image (network or local) with rounded corners.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(width * 0.02),
                          child:
                              image!.path.startsWith('https://')
                                  ? Image.network(
                                    image!.path,
                                    fit: BoxFit.cover,
                                  )
                                  : Image.file(
                                    File(image!.path),
                                    fit: BoxFit.cover,
                                  ),
                        ),
                        // Remove button positioned at top-right of the image preview.
                        Positioned(
                          top: height * 0.004,
                          right: width * 0.001,
                          child: GestureDetector(
                            onTap: onRemove,
                            child: CircleAvatar(
                              radius: width * 0.03,
                              backgroundColor: Colors.black.withAlpha(
                                128,
                              ),
                              child: Icon(
                                Icons.close,
                                size: width * 0.05,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }
}
