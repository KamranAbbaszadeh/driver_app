// Defines the different states used by NotificationBloc to manage UI updates.
// States include loading, loaded (with messages), and error.

/// Base class for all notification states.
/// Used to represent loading, success, or failure of notification operations.
abstract class NotificationState {}

/// State representing that notifications are currently being loaded.
class NotificationLoading extends NotificationState {}

/// State representing successful load of notification messages.
/// Includes a list of messages and whether all are viewed.
class NotificationLoaded extends NotificationState {
  /// The list of notification messages.
  final List<Map<String, dynamic>> messages;

  /// Flag indicating whether all messages have been viewed.
  final bool isAllViewed;

  NotificationLoaded(this.messages, this.isAllViewed);
}

/// State representing an error occurred while loading notifications.
class NotificationError extends NotificationState {
  /// Error message describing the failure reason.
  final String message;

  NotificationError(this.message);
}
