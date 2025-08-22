// Displays the user's past and filtered ride history using a calendar heatmap.
// Allows toggling between all rides or only those from a selected date.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/ride/active_vehicle_provider.dart';
import 'package:onemoretour/back/tools/subscription_manager.dart';
import 'package:onemoretour/front/displayed_items/tours/my_rides.dart';
import 'package:onemoretour/front/tools/ride_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onemoretour/front/tools/top_padding_provider.dart';

/// Widget that shows user's rides as a heatmap calendar and a list of rides by date.
/// Supports filtering based on vehicle and role (driver or guide).
class MyRidesBody extends ConsumerStatefulWidget {
  const MyRidesBody({super.key});

  @override
  ConsumerState<MyRidesBody> createState() => _MyRidesBodyState();
}

class _MyRidesBodyState extends ConsumerState<MyRidesBody> {
  List<Ride> carRides = [];
  List<Ride> guideRides = [];
  List<Ride> filteredRidesbyDate = [];
  List<Ride> filteredCarRidesByDate = [];
  List<Ride> filteredGuideRidesByDate = [];
  Map<String, dynamic>? userData;
  Map<String, dynamic>? vehicleData;
  Map<DateTime, int> datasets = {};
  bool showAllRides = true;
  late ScrollController _scrollController;

  StreamSubscription<QuerySnapshot>? carsSubscription;

  /// Retrieves user's personal and vehicle data from Firestore.
  /// Triggers ride loading once both are available.
  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userId = user.uid;

      FirebaseApi.instance.saveFCMToken(userId);
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .get();

      if (docSnapshot.exists && mounted) {
        setState(() {
          userData = docSnapshot.data();
        });

        final carName = userData!['Active Vehicle'] ?? '';
        final vehicleDoc =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .collection('Vehicles')
                .doc(carName)
                .get();
        if (docSnapshot.exists && mounted) {
          setState(() {
            vehicleData = vehicleDoc.data();
          });
        }
        if (userData == null || vehicleData == null) return;
        fetchAndFilterRides(userData: userData!, vehicleData: vehicleData!);
      }
    } catch (e) {
      logger.e('Error fetching user\'s data: $e');
    }
  }

  /// Fetches rides from 'Cars' and 'Guide' collections based on user role and filters them.
  /// Populates internal state and ride dataset.
  Future<void> fetchAndFilterRides({
    required Map<String, dynamic> userData,
    required Map<String, dynamic> vehicleData,
  }) async {
    if (userData['Role'] == 'Driver' ||
        userData['Role'] == 'Driver Cum Guide') {
      carsSubscription = FirebaseFirestore.instance
          .collection('Cars')
          .snapshots()
          .listen((querySnapshot) {
            final allRides =
                querySnapshot.docs.map((doc) {
                  final data = doc.data();
                  data['collectionSource'] = 'Cars';
                  return Ride.fromFirestore(data: data, id: doc.id);
                }).toList();
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;
            final userId = user.uid;
            final filtered =
                allRides.where((ride) {
                  return ride.driver == userId &&
                      ride.vehicleRegistrationNumber ==
                          vehicleData['Vehicle Registration Number'] &&
                      ride.isCompleted == false;
                }).toList();

            if (mounted) {
              setState(() {
                carRides = filtered;
                populateDatasets(carRides + guideRides);
              });
            }
          });

      SubscriptionManager.add(carsSubscription!);
    }

    if (userData['Role'] == 'Guide' || userData['Role'] == 'Driver Cum Guide') {
      FirebaseFirestore.instance.collection('Guide').snapshots().listen((
        querySnapshot,
      ) {
        final allRides =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['collectionSource'] = 'Guide';
              return Ride.fromFirestore(data: data, id: doc.id);
            }).toList();
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        final userId = user.uid;
        final filtered =
            allRides.where((ride) {
              return ride.driver == userId ||
                  ride.guide == userId && ride.isCompleted == false;
            }).toList();

        if (mounted) {
          setState(() {
            guideRides = filtered;
            populateDatasets(carRides + guideRides);
          });
        }
      });
    }
  }

  /// Fills the heatmap data (datasets) with ride completion status per day.
  void populateDatasets(List<Ride> rides) {
    datasets.clear();

    for (int i = 0; i < carRides.length + guideRides.length; i++) {
      (carRides + guideRides)[i].routes.forEach((key, route) {
        if (route['StartDate'] != null) {
          final startDate = DateTime.parse(route['StartDate']);

          final dateKey = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );

          if (route['Start Arrived'] == true && route['End Arrived'] == true) {
            datasets.update(dateKey, (key) => 2, ifAbsent: () => 2);
          } else {
            datasets.update(dateKey, (key) => 1, ifAbsent: () => 1);
          }
        }
      });
    }
  }

  /// Filters car and guide rides by a selected date from the heatmap.
  Future<void> filterRidesbyDate({required DateTime selectedDate}) async {
    filteredCarRidesByDate =
        carRides.where((ride) {
          for (var route in ride.routes.values) {
            if (route is Map && route['StartDate'] != null) {
              final rideDate = DateTime.parse(route['StartDate']);
              if (rideDate.year == selectedDate.year &&
                  rideDate.month == selectedDate.month &&
                  rideDate.day == selectedDate.day) {
                return true;
              }
            }
          }
          return false;
        }).toList();

    filteredGuideRidesByDate =
        guideRides.where((ride) {
          for (var route in ride.routes.values) {
            if (route is Map && route['StartDate'] != null) {
              final rideDate = DateTime.parse(route['StartDate']);
              if (rideDate.year == selectedDate.year &&
                  rideDate.month == selectedDate.month &&
                  rideDate.day == selectedDate.day) {
                return true;
              }
            }
          }
          return false;
        }).toList();

    setState(() {});
  }

  @override
  void initState() {
    fetchUserData();
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Future.microtask(() {
      ref.listenManual<AsyncValue<String?>>(activeVehicleProvider, (
        previous,
        next,
      ) async {
        next.whenData((vehicleId) async {
          if (vehicleId != null && userData != null) {
            final vehicleDoc =
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('Vehicles')
                    .doc(vehicleId)
                    .get();

            if (mounted) {
              setState(() {
                vehicleData = vehicleDoc.data();
              });
              fetchAndFilterRides(
                userData: userData!,
                vehicleData: vehicleData!,
              );
            }
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final today = DateTime.now();
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = ref.watch(topPaddingProvider);
    final bottomPadding = mediaQuery.padding.bottom;

    final appBarHeight = height * 0.075;
    final bottomNavHeight = height * 0.1;
    final availableHeight =
        screenHeight -
        topPadding -
        bottomPadding -
        appBarHeight -
        bottomNavHeight;
    return SingleChildScrollView(
      controller: _scrollController,
      child: Container(
        width: width,
        constraints: BoxConstraints(
          minHeight: availableHeight,
          maxHeight: double.infinity,
        ),
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
                // Display heatmap of ride activity, colored by route completion.
                HeatMapCalendar(
                  defaultColor: Colors.white,
                  size: width * 0.1,
                  flexible: true,
                  colorMode: ColorMode.color,
                  showColorTip: false,
                  monthFontSize: width * 0.05,
                  textColor: Colors.black,
                  initDate: today,
                  weekTextColor: Theme.of(context).textTheme.bodyMedium?.color,
                  datasets: datasets,
                  colorsets: {
                    1: const Color.fromARGB(255, 231, 1, 55),
                    2: const Color.fromARGB(255, 103, 168, 120),
                  },

                  onClick: (value) async {
                    await filterRidesbyDate(selectedDate: value);
                    setState(() {
                      showAllRides = false;
                    });
                  },
                  fontSize: width * 0.035,
                ),
                SizedBox(height: height * 0.011),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Section title with option to reset ride filter and show all rides.
                    Text(
                      'My Rides',
                      style: GoogleFonts.daysOne(
                        fontSize: width * 0.055,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Material(
                      color:
                          showAllRides
                              ? Colors.grey.shade400
                              : (darkMode
                                  ? const Color.fromARGB(255, 52, 168, 235)
                                  : const Color.fromARGB(255, 1, 105, 170)),
                      borderRadius: BorderRadius.circular(width * 0.01),
                      child: InkWell(
                        onTap:
                            showAllRides
                                ? null
                                : () {
                                  setState(() {
                                    showAllRides = true;
                                  });
                                },
                        borderRadius: BorderRadius.circular(width * 0.01),
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.01),
                          child: Text(
                            'Show All Rides',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w600,
                              color: darkMode ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.011),

                if (showAllRides) ...[
                  if (carRides.isNotEmpty) ...[
                    // Display section for ride tours of selected type.
                    Text(
                      'Ride Tours',
                      style: GoogleFonts.lexend(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    MyRides(
                      filteredRides: carRides,
                      parentScrollController: _scrollController,
                    ),
                    SizedBox(height: height * 0.02),
                  ],
                  if (guideRides.isNotEmpty) ...[
                    Text(
                      'Guide Tours',
                      style: GoogleFonts.lexend(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    MyRides(
                      filteredRides: guideRides,
                      parentScrollController: _scrollController,
                    ),
                  ] else if (guideRides.isEmpty && carRides.isEmpty) ...[
                    // Show fallback message when no rides are available for selected date or overall.
                    Center(
                      child: Text(
                        'No tours available. Press the "Rides" and grab a ride!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cabin(
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  if (filteredCarRidesByDate.isEmpty &&
                      filteredGuideRidesByDate.isEmpty) ...[
                    Center(
                      child: Text(
                        'No rides available for the selected day',
                        style: GoogleFonts.cabin(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    if (filteredCarRidesByDate.isNotEmpty) ...[
                      Text(
                        'Ride Tours',
                        style: GoogleFonts.lexend(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      MyRides(
                        filteredRides: filteredCarRidesByDate,
                        parentScrollController: _scrollController,
                      ),
                      SizedBox(height: height * 0.02),
                    ],
                    if (filteredGuideRidesByDate.isNotEmpty) ...[
                      Text(
                        'Guide Tours',
                        style: GoogleFonts.lexend(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      MyRides(
                        filteredRides: filteredGuideRidesByDate,
                        parentScrollController: _scrollController,
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
