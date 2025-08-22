// Model class representing a Ride document from Firestore.
// Includes fields for ride details, such as timing, vehicle, driver, guide, and route.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single ride entry retrieved from Firestore.
/// Contains metadata such as tour name, start/end time, route, and assigned personnel.
class Ride {
  String tourName;
  String category;
  bool transfer;
  Timestamp startDate;
  Timestamp endDate;
  int numOfGuests;
  GeoPoint pickUpLocation;
  int price;
  Map<String, dynamic> routes;
  String vehicleType;
  String driver;
  String? guide;
  String docId;
  String language;
  String? collectionSource;
  String? vehicleRegistrationNumber;
  bool? isCompleted;

  Ride({
    required this.tourName,
    required this.category,
    required this.transfer,
    required this.startDate,
    required this.endDate,
    required this.numOfGuests,
    required this.pickUpLocation,
    required this.price,
    required this.routes,
    required this.vehicleType,
    required this.driver,
    this.guide,
    required this.docId,
    required this.language,
    this.collectionSource,
    required this.vehicleRegistrationNumber,
    required this.isCompleted,
  });

  /// Factory constructor for creating a Ride object from Firestore data.
  /// Maps Firestore field names to Ride class properties, with default fallbacks where necessary.
  factory Ride.fromFirestore({
    required Map<String, dynamic> data,
    required String id,
  }) {
    return Ride(
      tourName: data['TourName'],
      category: data['Category'] ?? '',
      transfer: data['Transfer?'],
      startDate: data['StartDate'],
      endDate: data['EndDate'],
      numOfGuests: data['NumberofGuests'],
      pickUpLocation: data['Pickuplocation'],
      price: data['Price'],
      routes: data['Routes'],
      vehicleType: data['Vehicle'] ?? '',
      driver: data['Driver'] ?? '',
      guide: data['Guide'] ?? '',
      docId: id,
      language: data['Languages'] ?? '',
      collectionSource: data['collectionSource'],
      vehicleRegistrationNumber: data['VehicleRegistrationNumber'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}
