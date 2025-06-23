bool validateEmail(String email) {
  final trimmed = email.trim();
  final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
  return emailRegex.hasMatch(trimmed);
}
