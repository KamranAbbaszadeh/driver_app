// Defines the [Message] model for chat messages exchanged in the app.
// Includes sender info, message text, timestamp, and read status.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat message sent by a user.
/// Includes metadata such as sender UID, name, position, timestamp, and read status.
class Message {
  final String userUID;
  final Timestamp createdAt;
  final bool isRead;
  final String message;
  final String name;
  final String position;

  Message({
    required this.userUID,
    required this.createdAt,
    required this.isRead,
    required this.message,
    required this.name,
    required this.position,
  });

  /// Converts the [Message] object into a Firestore-compatible map for storage.
  Map<String, dynamic> toMap() {
    return {
      'UID': userUID,
      'createdAt': createdAt,
      'isRead': isRead,
      'message': message,
      'name': name,
      'position': position,
    };
  }
}
