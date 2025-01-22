import 'package:driver_app/back/api/get_stored_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(false) {
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    List<Map<String, dynamic>> messages = await getStoredMessages();
    bool newState = messages.any((message) => message['isViewed'] == false);

    if (state != newState) {

      state = newState;
    } 
  }

  Future<void> refresh() async {
    await _checkNotifications();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, bool>((ref) {
      return NotificationsNotifier();
    });
