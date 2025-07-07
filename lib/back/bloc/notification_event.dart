// Defines the events used by the NotificationBloc to manage notification state.
// Events include fetching, deleting, and marking notifications as viewed.

/// Base class for all notification-related events dispatched to NotificationBloc.
abstract class NotificationEvent {}

/// Event to trigger loading notifications from local storage.
class FetchNotifications extends NotificationEvent {}

/// Event to delete all stored notifications.
class DeleteNotifications extends NotificationEvent {}

/// Event to mark all stored notifications as viewed.
class MarkAllAsViewed extends NotificationEvent {}

/// Event to mark a specific message as viewed by its index.
class MarkMessageAsViewed extends NotificationEvent {
  /// Index of the message to mark as viewed.
  final int index;

  MarkMessageAsViewed(this.index);
}
