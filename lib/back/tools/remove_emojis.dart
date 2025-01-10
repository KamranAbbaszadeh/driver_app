String removeEmojis(String input) {
    final emojiRegex = RegExp(r'(\uD83C[\uDDE6-\uDDFF]){2}');
    return input.replaceAll(emojiRegex, '').trim();
  }