import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<void> markMessageAsViewed(int index) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? messagesString = prefs.getString('notification_messages');
  if (messagesString != null) {
    List<dynamic> messagesList = jsonDecode(messagesString);
    if (index >= 0 && index < messagesList.length) {
      messagesList[index]['isViewed'] = true;
      await prefs.setString('notification_messages', jsonEncode(messagesList));
    }
  }
}
