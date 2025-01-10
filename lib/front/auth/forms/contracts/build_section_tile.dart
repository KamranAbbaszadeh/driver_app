import 'package:flutter/material.dart';

Widget buildSectionTitle(String title, double width) {
  return Text(
    title,
    style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold),
  );
}
