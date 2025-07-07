// A custom [TextInputFormatter] that automatically converts input text to uppercase.
// Useful for form fields that require standardized capitalization (e.g., license plates or names).
import 'package:flutter/services.dart';

/// A [TextInputFormatter] that transforms all entered text to uppercase.
/// Overrides [formatEditUpdate] to ensure consistent capitalization.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert the new text to uppercase while preserving cursor position.
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
