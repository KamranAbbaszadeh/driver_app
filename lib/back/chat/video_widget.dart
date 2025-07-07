// Widget for displaying a video file using the `video_player` package.
// Initializes the video controller on creation and disposes it when the widget is removed.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A widget that plays a local video file using [VideoPlayerController].
/// Takes a [File] and renders the video once it is initialized.
class VideoWidget extends StatefulWidget {
  final File file;

  const VideoWidget({super.key, required this.file});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;

  /// Initializes the video controller with the provided file and triggers rebuild once ready.
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  /// Disposes the video controller to release resources when the widget is removed.
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show the video if initialized, otherwise display a loading spinner.
    return _controller.value.isInitialized
        ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
        : Center(child: CircularProgressIndicator());
  }
}
