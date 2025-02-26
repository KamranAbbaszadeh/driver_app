import 'package:cloud_firestore/cloud_firestore.dart';

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
