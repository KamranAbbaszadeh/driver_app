abstract class NotificationEvent {}

class FetchNotifications extends NotificationEvent {}

class DeleteNotifications extends NotificationEvent {}

class MarkAllAsViewed extends NotificationEvent {}

class MarkMessageAsViewed extends NotificationEvent {
  final int index;

  MarkMessageAsViewed(this.index);
}
