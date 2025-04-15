import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class RideHistory {
  final int price;
  final String driver;
  final String tourName;
  final DateTime startDate;
  final bool isPaid;
  final bool isCompleted;
  final DateTime endDate;
  final int numOfGuests;
  final int numOfRoutes;
  final List<Map<String, dynamic>> routes;

  RideHistory({
    required this.price,
    required this.driver,
    required this.startDate,
    required this.isPaid,
    required this.isCompleted,
    required this.endDate,
    required this.tourName,
    required this.numOfGuests,
    required this.numOfRoutes,
    required this.routes,
  });

  factory RideHistory.fromFirestore({required Map<String, dynamic> data}) {
    final routesMap = data['Routes'] as Map<String, dynamic>? ?? {};
    final routesList = routesMap.values.map((e) => e as Map<String, dynamic>).toList();
    return RideHistory(
      price: data['Price'] ?? 0.0,
      driver: data['Driver'],
      tourName: data['TourName'] ?? '',
      numOfGuests: data['NumberofGuests'] ?? 0,
      startDate: (data['StartDate'] as Timestamp).toDate(),
      endDate: (data['EndDate'] as Timestamp).toDate(),
      numOfRoutes: data['Routes'].length ?? 0,
      isPaid: data['isPaid'] ?? false,
      isCompleted: data['isCompleted'] ?? false,
      routes: routesList,
    );
  }
 double get totalDistanceKm {
    double total = 0.0;

    for (var route in routes) {
      try {
        final startParts = (route['Start'] as String).split(',').map((s) => double.parse(s.trim())).toList();
        final endParts = (route['End'] as String).split(',').map((s) => double.parse(s.trim())).toList();

        total += calculateDistance(
          startParts[0], startParts[1],
          endParts[0], endParts[1],
        );
      } catch (e) {
        continue;
      }
    }

    return total;
  }
}


double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371;
  double dLat = _degToRad(lat2 - lat1);
  double dLon = _degToRad(lon2 - lon1);
  double a = sin(dLat / 2) * sin(dLat / 2) +
             cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
             sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _degToRad(double deg) => deg * (pi / 180);

