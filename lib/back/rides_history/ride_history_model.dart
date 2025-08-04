// Defines the RideHistory model used for storing and displaying past ride data.
// Includes Firestore deserialization, total distance calculation from route coordinates, and ride metadata.

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a completed or historical ride.
/// Contains details such as driver, tour, route data, payment and completion status, and distance metrics.
class RideHistory {
  final int price;
  final int fine;
  final String driver;
  final String tourName;
  final DateTime startDate;
  final bool isPaid;
  final bool isCompleted;
  final DateTime endDate;
  final int numOfGuests;
  final int numOfRoutes;
  final List<Map<String, dynamic>> routes;
  final String vehicleType;
  final String category;
  final String guide;
  final String docId;

  RideHistory({
    required this.price,
    required this.fine,
    required this.driver,
    required this.startDate,
    required this.isPaid,
    required this.isCompleted,
    required this.endDate,
    required this.tourName,
    required this.numOfGuests,
    required this.numOfRoutes,
    required this.routes,
    required this.vehicleType,
    required this.guide,
    required this.category,
    required this.docId,
  });

  /// Creates a [RideHistory] instance from Firestore document data and ID.
  /// Converts route data and timestamps, and assigns default values for missing fields.
  factory RideHistory.fromFirestore({
    required Map<String, dynamic> data,
    required String id,
  }) {
    final routesMap = data['Routes'] as Map<String, dynamic>? ?? {};
    final routesList =
        routesMap.values.map((e) => e as Map<String, dynamic>).toList();

    return RideHistory(
      docId: id,
      price: (data['Price'] as num?)?.toInt() ?? 0,
      fine: (data['Fine'] as num?)?.toInt() ?? 0,
      driver: data['Driver'] ?? '',
      guide: data['Guide'] ?? '',
      tourName: data['TourName'] ?? '',
      numOfGuests: data['NumberofGuests'] ?? 0,
      startDate: (data['StartDate'] as Timestamp).toDate(),
      endDate: (data['EndDate'] as Timestamp).toDate(),
      numOfRoutes: data['Routes'].length ?? 0,
      isPaid: data['isPaid'] ?? false,
      isCompleted: data['isCompleted'] ?? false,
      routes: routesList,
      vehicleType: data['Vehicle'] ?? '',
      category: data['Category'] ?? '',
    );
  }

  /// Calculates the total distance of all ride routes in kilometers using haversine formula.
  /// Iterates through 'Start' and 'End' coordinate strings in the routes list.
  double get totalDistanceKm {
    double total = 0.0;

    for (var route in routes) {
      try {
        final startParts =
            (route['Start'] as String)
                .split(',')
                .map((s) => double.parse(s.trim()))
                .toList();
        final endParts =
            (route['End'] as String)
                .split(',')
                .map((s) => double.parse(s.trim()))
                .toList();

        total += calculateDistance(
          startParts[0],
          startParts[1],
          endParts[0],
          endParts[1],
        );
      } catch (e) {
        continue;
      }
    }

    return total;
  }
}

/// Computes distance between two geo-points using the haversine formula.
/// Returns distance in kilometers.
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371;
  double dLat = _degToRad(lat2 - lat1);
  double dLon = _degToRad(lon2 - lon1);
  double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

/// Converts degrees to radians.
double _degToRad(double deg) => deg * (pi / 180);
