import 'dart:convert';
import 'package:onemoretour/back/bloc/notification_event.dart';
import 'package:onemoretour/back/bloc/notification_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onemoretour/back/api/get_stored_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationLoading()) {
    on<FetchNotifications>(_fetchNotifications);
    on<DeleteNotifications>(_deleteNotifications);
    on<MarkAllAsViewed>(_markAllAsViewed);
    on<MarkMessageAsViewed>(_markMessageAsViewed);
  }

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
