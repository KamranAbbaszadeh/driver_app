// Utility function to validate email addresses using a regular expression.
// Ensures input is properly trimmed and matches a basic email pattern.

/// Validates the given [email] string.
/// Returns true if it matches the email regex pattern, false otherwise.
/// Trims the input before applying validation.
bool validateEmail(String email) {
  final trimmed = email.trim();
  final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
  return emailRegex.hasMatch(trimmed);
}
