// Provides utility functions to interact with locally stored notification messages.
// Supports retrieving the message list and marking a message as viewed.
import 'dart:convert';
import 'package:onemoretour/front/tools/notification_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Retrieves a list of locally stored notification messages from SharedPreferences.
/// Parses the stored JSON string into a list of message maps.
Future<List<Map<String, dynamic>>> getStoredMessages() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? messagesString = prefs.getString('notification_messages');
  if (messagesString != null) {
    List<dynamic> messagesList = jsonDecode(messagesString);
    return messagesList
        .map((message) => Map<String, dynamic>.from(message))
        .toList();
  }
  return [];
}

/// Marks a notification message as viewed at the given index.
/// Updates the stored list and triggers a refresh of the notificationsProvider.
Future<void> markMessageAsViewed(int index, WidgetRef ref) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? messagesString = prefs.getString('notification_messages');
  if (messagesString != null) {
    List<dynamic> messagesList = jsonDecode(messagesString);
    if (index >= 0 && index < messagesList.length) {
      messagesList[index]['isViewed'] = true;
      await prefs.setString('notification_messages', jsonEncode(messagesList));
      ref.read(notificationsProvider.notifier).refresh();
    }
  }
}
