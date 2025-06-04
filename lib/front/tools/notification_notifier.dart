import 'package:firebase_auth/firebase_auth.dart';
import 'package:onemoretour/back/api/get_stored_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  NotificationsNotifier() : super([]) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    List<Map<String, dynamic>> messages = await getStoredMessages();
    state = messages;
  }

  Future<void> refresh() async {
    await _loadMessages();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<Map<String, dynamic>>>((
      ref,
    ) {
      return NotificationsNotifier();
    });
