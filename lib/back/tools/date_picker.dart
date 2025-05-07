import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:intl/intl.dart';

Future<void> selectDate({
  required BuildContext context,
  required TextEditingController controller,
}) async {
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  DateTime? selectedDate = await DatePicker.showSimpleDatePicker(
    context,
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
    initialDate:
        controller.text.isNotEmpty
            ? DateFormat('d/M/yyyy').parse(controller.text)
            : DateTime.now(),
    dateFormat: 'dd-MMMM-yyyy',
    backgroundColor:
        darkMode ? const Color.fromARGB(255, 30, 29, 29) : Colors.white,
    looping: true,
    titleText: 'Select your date of birth',
    confirmText: 'Done',
    reverse: true,
    textColor: darkMode ? Colors.white : const Color.fromARGB(255, 30, 29, 29),
  );

  if (selectedDate != null) {
    controller.text =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
  }
}
