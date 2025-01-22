import 'package:flutter/material.dart';

Widget buildSubsection(
  String title,
  String content,
  double height,
  double width,
  BuildContext context,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: width * 0.04,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      SizedBox(height: height * 0.011),
      Text(
        content,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
      SizedBox(height: height * 0.011),
    ],
  );
}
