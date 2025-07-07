// A fullscreen image viewer that displays an image from a given URL.
// Allows zooming and panning using [InteractiveViewer].
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A stateless widget that displays a network image in fullscreen mode.
/// Includes zoom and pan functionality, with a close button in the AppBar.
class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullscreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // Get screen width to scale the AppBar icon size responsively.
    final width = MediaQuery.of(context).size.width;
    // Build a fullscreen scaffold with dark background and zoomable image viewer.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {
            // Close the image viewer and return to the previous screen.
            Navigator.pop(context);
          },
          hoverColor: Colors.transparent,
          icon: Icon(
            Icons.arrow_circle_left_rounded,
            size: width * 0.1,
            color: Colors.grey.shade400,
          ),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          // Load and cache the network image with loading and error indicators.
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}
