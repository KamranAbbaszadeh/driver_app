// A custom widget that allows users to pick and display multiple photos.
// Displays a placeholder with instructions when no images are selected.
// Once images are selected, they are shown in a grid with an option to remove each one.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A photo picker widget with display grid and remove option.
/// Tapping opens image picker; displays uploaded images in a 3-column grid.
/// Shows label, minimum required photos, and visual theme depending on dark mode.
class PhotoPickerWithDisplay extends StatelessWidget {
  final List<XFile> images;
  final String label;
  final String minPhotos;
  final Future<void> Function() onPick;
  final Future<void> Function(int index) onRemove;
  final bool darkMode;
  final bool isDeclined;
  final String fieldName;

  const PhotoPickerWithDisplay({
    super.key,
    required this.images,
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
    // Get screen dimensions for responsive sizing.
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    // Wrap the whole input in a GestureDetector to trigger image picking.
    return GestureDetector(
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          // Show label only if images are selected.
          labelText: images.isNotEmpty ? fieldName : null,
          filled: true,
          // Set background color based on theme.
          fillColor: darkMode ? Colors.grey[900] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(width * 0.03),
          ),
          // Customize border color based on dark mode.
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(width * 0.03),
            borderSide: BorderSide(
              color: darkMode ? Colors.grey[700]! : Colors.grey[400]!,
            ),
          ),
        ),
        child:
            images.isEmpty
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon to suggest adding photos.
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: width * 0.1,
                      color: darkMode ? Colors.blue[300] : Colors.blueAccent,
                    ),
                    SizedBox(height: height * 0.009),
                    // Main label describing image purpose.
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: darkMode ? Colors.blue[100] : Colors.blueGrey,
                      ),
                    ),
                    SizedBox(height: height * 0.005),
                    // Show required minimum number of photos.
                    Text(
                      'Minimum: $minPhotos photos',
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
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final photo = images[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Display image from network or local file with rounded corners.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(width * 0.02),
                          child:
                              photo.path.startsWith('https://')
                                  ? Image.network(photo.path, fit: BoxFit.cover)
                                  : Image.file(
                                    File(photo.path),
                                    fit: BoxFit.cover,
                                  ),
                        ),
                        // Add a remove button on the top-right corner of each image.
                        Positioned(
                          top: height * 0.004,
                          right: width * 0.001,
                          child: GestureDetector(
                            onTap: () => onRemove(index),
                            child: CircleAvatar(
                              radius: width * 0.03,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.5,
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
