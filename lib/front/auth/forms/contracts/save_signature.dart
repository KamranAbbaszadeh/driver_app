import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

Future<Uint8List?> saveSignature({
  required GlobalKey<SfSignaturePadState> signaturePadKey,
  required String userID,
}) async {
  try {
    final signature = await signaturePadKey.currentState?.toImage();
    if (signature == null) {
      return null;
    }

    final byteData = await signature.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) return null;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final double width = signature.width.toDouble();
    final double height = signature.height.toDouble();
    final Matrix4 flipVertical =
        Matrix4.identity()
          ..translate(0.0, height)
          ..scale(1.0, -1.0);

    canvas.transform(flipVertical.storage);
    canvas.drawImage(signature, Offset.zero, Paint());

    final ui.Image flippedImage = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );

    final ByteData? flippedByteData = await flippedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (flippedByteData == null) return null;

    return flippedByteData.buffer.asUint8List();
  } catch (e) {
    return null;
  }
}
