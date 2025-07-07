// Bloc implementation for handling app notification states and events.
// Manages fetching, deleting, and marking notifications as viewed using local storage.
import 'dart:convert';
import 'package:onemoretour/back/bloc/notification_event.dart';
import 'package:onemoretour/back/bloc/notification_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onemoretour/back/api/get_stored_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bloc class that handles notification-related logic:
/// - Fetches stored notifications
/// - Deletes all notifications
/// - Marks all or individual messages as viewed
/// Uses SharedPreferences for local persistence.
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationLoading()) {
    on<FetchNotifications>(_fetchNotifications);
    on<DeleteNotifications>(_deleteNotifications);
    on<MarkAllAsViewed>(_markAllAsViewed);
    on<MarkMessageAsViewed>(_markMessageAsViewed);
  }

  /// Loads notification messages from SharedPreferences.
  /// Emits [NotificationLoading], then [NotificationLoaded] or [NotificationError].
  Future<void> _fetchNotifications(
    FetchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final messages = await getStoredMessages();
      final isAllViewed = messages.every(
        (message) => message['isViewed'] == true,
      );
      emit(NotificationLoaded(messages, isAllViewed));
    } catch (e) {
      emit(NotificationError('Error loading notifications: $e'));
    }
  }

  /// Clears all saved notification messages from SharedPreferences.
  /// Emits [NotificationLoaded] with an empty list.
  Future<void> _deleteNotifications(
    DeleteNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_messages');
      emit(NotificationLoaded([], true));

      await _fetchNotifications(FetchNotifications(), emit);
    } catch (e) {
      emit(NotificationError('Error deleting notifications: $e'));
    }
  }

  /// Marks all messages as viewed by updating the local SharedPreferences store.
  /// Re-emits [NotificationLoaded] with updated messages.
  Future<void> _markAllAsViewed(
    MarkAllAsViewed event,
    Emitter<NotificationState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesString = prefs.getString('notification_messages');
    if (messagesString != null) {
      final messagesList =
          (jsonDecode(messagesString) as List)
              .map((message) => Map<String, dynamic>.from(message))
              .toList();
      for (final message in messagesList) {
        message['isViewed'] = true;
      }
      await prefs.setString('notification_messages', jsonEncode(messagesList));
      emit(NotificationLoaded(messagesList, true));
      await _fetchNotifications(FetchNotifications(), emit);
    }
  }

  /// Marks a specific message (by index) as viewed and updates SharedPreferences.
  /// Emits a new [NotificationLoaded] state with updated view status.
  Future<void> _markMessageAsViewed(
    MarkMessageAsViewed event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      final messages = List<Map<String, dynamic>>.from(currentState.messages);
      messages[event.index]['isViewed'] = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_messages', jsonEncode(messages));

      emit(NotificationLoaded(messages, messages.every((m) => m['isViewed'])));
    }
  }
}
