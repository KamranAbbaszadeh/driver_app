abstract class NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<Map<String, dynamic>> messages;

  final bool isAllViewed;

  NotificationLoaded(this.messages, this.isAllViewed);
}

class NotificationError extends NotificationState {
  final String message;

  NotificationError(this.message);
}
