import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: image != null ? fieldName : null,
          filled: true,
          fillColor: darkMode ? Colors.grey[900] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(width * 0.04),
          ),
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
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: width * 0.1,
                      color: darkMode ? Colors.blue[300] : Colors.blueAccent,
                    ),
                    SizedBox(height: height * 0.005),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: darkMode ? Colors.blue[100] : Colors.blueGrey,
                      ),
                    ),
                    SizedBox(height: height * 0.005),
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
                        Positioned(
                          top: height * 0.004,
                          right: width * 0.001,
                          child: GestureDetector(
                            onTap: onRemove,
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
