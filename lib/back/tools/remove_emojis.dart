// Utility function to remove country flag emojis from a given input string.
// Useful for sanitizing text fields or inputs where emoji characters are not supported.

/// Removes country flag emojis (e.g., 🇺🇸, 🇬🇧) from the given [input] string.
/// Returns a trimmed string without these emoji characters.
String removeEmojis(String input) {
  final emojiRegex = RegExp(r'(\uD83C[\uDDE6-\uDDFF]){2}');
  return input.replaceAll(emojiRegex, '').trim();
}
