import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  String tourName;
  bool transfer;
  Timestamp startDate;
  Timestamp endDate;
  int numOfGuests;
  GeoPoint pickUpLocation;
  int price;
  Map<String, dynamic> routes;
  String vehicleType;
  String driver;
  String docId;

  Ride({
    required this.tourName,
    required this.transfer,
    required this.startDate,
    required this.endDate,
    required this.numOfGuests,
    required this.pickUpLocation,
    required this.price,
    required this.routes,
    required this.vehicleType,
    required this.driver,
    required this.docId,
  });

  factory Ride.fromFirestore({
    required Map<String, dynamic> data,
    required String id,
  }) {
    return Ride(
      tourName: data['TourName'],
      transfer: data['Transfer?'],
      startDate: data['StartDate'],
      endDate: data['EndDate'],
      numOfGuests: data['NumberofGuests'],
      pickUpLocation: data['Pickuplocation'],
      price: data['Price'],
      routes: data['Routes'],
      vehicleType: data['Category'],
      driver: data['Driver'],
      docId: id,
    );
  }
}
