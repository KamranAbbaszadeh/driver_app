// A utility function to display a date picker dialog using the flutter_holo_date_picker package.
// Updates a given [TextEditingController] with the selected date in dd/MM/yyyy format.
// Supports dark and light themes and customizes the picker appearance.
import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:intl/intl.dart';

/// Displays a date picker and assigns the selected date to [controller].
/// Parses existing text (if any) to set as initial date.
/// Applies theming based on platform brightness and allows date range selection from 1900 to today.
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
