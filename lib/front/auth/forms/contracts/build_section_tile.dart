import 'package:flutter/material.dart';

Widget buildSectionTitle(String title, double width, BuildContext context) {
  return Text(
    title,
    style: TextStyle(
      fontSize: width * 0.045,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).textTheme.bodyMedium?.color,
    ),
  );
}
