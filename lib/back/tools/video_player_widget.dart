// A widget that plays a video from a given network URL and displays a small preview.
// When tapped, it opens a full-screen dialog with play/pause functionality.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A widget that shows a thumbnail preview of a network video.
/// Tapping the preview opens a larger dialog where the user can play or pause the video.
class VideoPlayerWidget extends StatefulWidget {
  final Uri videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? SizedBox(
          width: 150 * _controller.value.aspectRatio,
          height: 150 * _controller.value.aspectRatio,
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                IconButton(
                  icon: Icon(Icons.play_arrow, color: Colors.white),
                  onPressed: _showVideoDialog,
                ),
              ],
            ),
          ),
        )
        : Center(child: CircularProgressIndicator());
  }

  /// Displays a dialog containing the video player with a play/pause toggle.
  /// Uses a transparent background and a fixed height for the video.
  void _showVideoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: double.infinity,
            height: 400,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder:
                        (_, value, _) => Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                  ),
                  onPressed: () {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
