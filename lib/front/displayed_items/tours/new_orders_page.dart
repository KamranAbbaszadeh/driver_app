import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/front/displayed_items/tours/my_rides.dart';
import 'package:driver_app/front/tools/ride_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewOrdersPage extends StatefulWidget {
  const NewOrdersPage({super.key});

  @override
  State<NewOrdersPage> createState() => _NewOrdersPageState();
}

class _NewOrdersPageState extends State<NewOrdersPage> {
  List<Ride> filteredRides = [];
  Map<String, dynamic>? userData;
  StreamSubscription<DocumentSnapshot>? userSubscription;
  StreamSubscription<QuerySnapshot>? carsSubscription;

  @override
  void initState() {
    super.initState();
    listenToUserData();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    carsSubscription?.cancel();
    super.dispose();
  }

  void listenToUserData() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      userSubscription = FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .snapshots()
          .listen((docSnapshot) {
            if (docSnapshot.exists) {
              setState(() {
                userData = docSnapshot.data();
              });
              listenToRidesUpdates(); // Reinitialize ride listener if user data changes
            }
          });
    }
  }

  void listenToRidesUpdates() {
    if (userData == null) return;

    carsSubscription
        ?.cancel(); // Cancel the previous subscription to avoid duplicates
    carsSubscription = FirebaseFirestore.instance
        .collection('Cars')
        .snapshots()
        .listen((querySnapshot) {
          final allRides =
              querySnapshot.docs
                  .map(
                    (doc) => Ride.fromFirestore(data: doc.data(), id: doc.id),
                  )
                  .toList();

          try {
            final filtered =
                allRides.where((ride) {
                  final tourStartDate = ride.startDate.toDate();
                  final userTourEndDate = userData!['Tour end Date'];

                  return ride.vehicleType == userData!['Vehicle type'] &&
                      ride.numOfGuests <=
                          userData!['Vehicle Details']['Seat Number'] &&
                      tourStartDate.isAfter(userTourEndDate.toDate()) &&
                      ride.driver == '';
                }).toList();

            setState(() {
              filteredRides = filtered;
            });
          } catch (e) {
            logger.e('Error fetching routes: $e');
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              darkMode
                  ? [Color.fromARGB(255, 1, 105, 170), Colors.black]
                  : [Color.fromARGB(255, 52, 168, 235), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.04),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.011),
              Text(
                'Rides',
                style: GoogleFonts.daysOne(
                  fontSize: width * 0.055,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: height * 0.011),
              MyRides(filteredRides: filteredRides, height: height * 0.77),
            ],
          ),
        ),
      ),
    );
  }
}
