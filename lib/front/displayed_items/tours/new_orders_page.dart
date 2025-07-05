import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/tools/subscription_manager.dart';
import 'package:onemoretour/front/displayed_items/tours/my_rides.dart';
import 'package:onemoretour/front/tools/ride_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';

class NewOrdersPage extends StatefulWidget {
  const NewOrdersPage({super.key});

  @override
  State<NewOrdersPage> createState() => _NewOrdersPageState();
}

class _NewOrdersPageState extends State<NewOrdersPage> {
  List<Ride> filteredRidesFromCars = [];
  List<Ride> filteredRidesFromGuide = [];
  Map<String, dynamic>? userData;
  StreamSubscription<DocumentSnapshot>? userSubscription;
  StreamSubscription? carsSubscription;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    listenToUserData();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    carsSubscription?.cancel();
    _scrollController.dispose();

    super.dispose();
  }

  void listenToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    userSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            setState(() {
              userData = docSnapshot.data();
            });
            listenToRidesUpdates();
          }
        });
    SubscriptionManager.add(userSubscription!);
  }

  void listenToRidesUpdates() async {
    try {
      if (userData == null) return;
      final role = userData?['Role'];
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userId = user.uid;
      final activeVehicleId = userData?['Active Vehicle'] ?? 'Car1';
      final category = List<String>.from(userData?['Allowed category'] ?? []);

      final vehicleDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .collection('Vehicles')
              .doc(activeVehicleId)
              .get();

      if (!vehicleDoc.exists) {
        if (!mounted) return;
        setState(() {
          filteredRidesFromCars = [];
          filteredRidesFromGuide = [];
        });
        return;
      }

      final seatNumber = vehicleDoc.data()?['Seat Number'];
      final allowedVehicles = List<String>.from(
        vehicleDoc.data()?['Allowed Vehicle'] ?? [],
      );

      if (seatNumber == null || allowedVehicles.isEmpty) {
        if (!mounted) return;
        setState(() {
          filteredRidesFromCars = [];
          filteredRidesFromGuide = [];
        });
        return;
      }

      carsSubscription?.cancel();

      final carStream =
          FirebaseFirestore.instance.collection('Cars').snapshots();
      final guideStream =
          FirebaseFirestore.instance.collection('Guide').snapshots();

      void handleRides(List<Ride> rides) {
        try {
          final fromCars = <Ride>[];
          final fromGuide = <Ride>[];

          for (var ride in rides) {
            final tourStartDate = ride.startDate.toDate();
            final Timestamp? userTourEndTimestamp = userData?['Tour end Date'];
            if (userTourEndTimestamp == null) {
              continue;
            }

            final userTourEndDate = userTourEndTimestamp.toDate();

            final userLanguagesList =
                userData!['Language spoken']
                    .split(',')
                    .map((e) => e.trim())
                    .toList();

            final isFromCars = ride.collectionSource == 'Cars';
            final isFromGuide = ride.collectionSource == 'Guide';

            final matchDriver =
                isFromCars &&
                allowedVehicles.contains(ride.vehicleType) &&
                ride.numOfGuests <= seatNumber &&
                tourStartDate.isAfter(userTourEndDate) &&
                ride.driver == '';
            final rideLanguagesList =
                ride.language.split(',').map((e) => e.trim()).toList();
            final hasMatchingLanguage = rideLanguagesList.any(
              (lang) => userLanguagesList.contains(lang),
            );
            final matchGuide =
                isFromGuide &&
                hasMatchingLanguage &&
                category.contains(ride.category) &&
                tourStartDate.isAfter(userTourEndDate) &&
                tourStartDate.isAfter(DateTime.now()) &&
                ride.guide == '';

            if (matchDriver) fromCars.add(ride);
            if (matchGuide) fromGuide.add(ride);
          }

          if (!mounted) return;
          setState(() {
            filteredRidesFromCars = fromCars;
            filteredRidesFromGuide = fromGuide;
          });
        } catch (e) {
          logger.e('Error filtering routes: $e');
        }
      }

      if (role == 'Driver') {
        carsSubscription = carStream.listen((snapshot) async {
          final rides =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['collectionSource'] = 'Cars';
                return Ride.fromFirestore(
                  data: {...data, 'Driver': data['Driver'] ?? ''},
                  id: doc.id,
                );
              }).toList();
          handleRides(rides);
        });
      } else if (role == 'Guide') {
        carsSubscription = guideStream.listen((snapshot) async {
          final rides =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['collectionSource'] = 'Guide';
                return Ride.fromFirestore(data: data, id: doc.id);
              }).toList();
          handleRides(rides);
        });
      } else if (role == 'Driver Cum Guide') {
        carsSubscription = Rx.combineLatest2(carStream, guideStream, (
          QuerySnapshot carSnap,
          QuerySnapshot guideSnap,
        ) {
          final carRides =
              carSnap.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['collectionSource'] = 'Cars';
                return Ride.fromFirestore(
                  data: {...data, 'Driver': data['Driver'] ?? ''},
                  id: doc.id,
                );
              }).toList();
          final guideRides =
              guideSnap.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['collectionSource'] = 'Guide';
                return Ride.fromFirestore(data: data, id: doc.id);
              }).toList();
          return [...carRides, ...guideRides];
        }).listen((combinedRides) {
          handleRides(combinedRides);
        });
      }
      SubscriptionManager.add(carsSubscription!);
    } catch (e) {
      logger.e('Error listening to rides updates: $e');
    }
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
          child: SingleChildScrollView(
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
                if (userData == null)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: height * 0.15),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (userData != null &&
                    filteredRidesFromCars.isEmpty &&
                    filteredRidesFromGuide.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: height * 0.15),
                      child: Text(
                        'No new rides available',
                        style: GoogleFonts.notoSans(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (filteredRidesFromCars.isNotEmpty) ...[
                  Text(
                    userData?['Role'] != "Guide" ? 'Ride Tours' : '',
                    style: GoogleFonts.notoSans(
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  MyRides(
                    filteredRides: filteredRidesFromCars,
                    parentScrollController: _scrollController,
                  ),
                  SizedBox(height: height * 0.011),
                ],
                if (filteredRidesFromGuide.isNotEmpty) ...[
                  Text(
                    userData?['Role'] != "Driver" ? 'Guide Tours' : '',
                    style: GoogleFonts.notoSans(
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  MyRides(
                    filteredRides: filteredRidesFromGuide,
                    parentScrollController: _scrollController,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
