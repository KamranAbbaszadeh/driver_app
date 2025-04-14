import 'package:cloud_firestore/cloud_firestore.dart';

class RideHistory {
  final int price;
  final String driver;
  final DateTime startDate;
  final bool isPaid;
  final bool isCompleted;

  RideHistory({
    required this.price,
    required this.driver,
    required this.startDate,
    required this.isPaid,
    required this.isCompleted,
  });

  factory RideHistory.fromFirestore({required Map<String, dynamic> data}) {
    return RideHistory(
      price: data['Price'] ?? 0.0,
      driver: data['Driver'],
      startDate: (data['StartDate'] as Timestamp).toDate(),
      isPaid: data['isPaid'] ?? false,
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}
