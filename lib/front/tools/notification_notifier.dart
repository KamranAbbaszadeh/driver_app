// Riverpod notifier for managing the list of stored notifications for the current user.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onemoretour/back/api/get_stored_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads and manages a list of notifications stored locally or remotely.
/// Automatically fetches messages when initialized, and supports manual refresh.
class NotificationsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  NotificationsNotifier() : super([]) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    // Retrieve the currently authenticated user.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    // Fetch stored messages associated with the current user.
    List<Map<String, dynamic>> messages = await getStoredMessages();
    // Update state with fetched messages.
    state = messages;
  }

  Future<void> refresh() async {
    // Manually trigger re-fetching of stored messages.
    await _loadMessages();
  }
}

/// Riverpod provider for accessing notifications state throughout the app.
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<Map<String, dynamic>>>((
      ref,
    ) {
      return NotificationsNotifier();
    });
