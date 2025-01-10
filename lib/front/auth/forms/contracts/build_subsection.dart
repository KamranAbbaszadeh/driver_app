import 'package:flutter/material.dart';

Widget buildSubsection(
  String title,
  String content,
  double height,
  double width,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(fontSize: width * 0.04, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: height * 0.011),
      Text(content),
      SizedBox(height: height * 0.011),
    ],
  );
}
