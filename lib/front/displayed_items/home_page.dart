import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/map_and_location/get_functions.dart';
import 'package:driver_app/back/map_and_location/location_provider.dart';
import 'package:driver_app/back/ride/ride_state.dart';
import 'package:driver_app/front/displayed_items/ride_page.dart';
import 'package:driver_app/front/tools/app_bar.dart';
import 'package:driver_app/front/tools/bottom_bar_provider.dart';
import 'package:driver_app/front/tools/bottom_nav_bar.dart';
import 'package:driver_app/front/tools/list_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  StreamSubscription? _locationSubscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseApi.instance.checkAndRequestExactAlarmPermission(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestLocationPermissions(context);
    _locationSubscription = FlutterBackgroundService()
        .on('LocationUpdates')
        .listen((event) {
          if (event != null) {
            ref.read(locationProvider.notifier).state = event;
          }
        });
  }

  DateTime parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RideState>(rideProvider, (previous, next) {
      final prevRoute = previous?.nextRoute;
      final nextRoute = next.nextRoute;
      final currentDate = DateTime.now();
      final tourStartDate = parseDate(nextRoute?['StartDate']);
      final tourEndDate = parseDate(nextRoute?['EndDate']);
      final tourId = nextRoute?['ID'];

      if (prevRoute != nextRoute) {
        setState(() {});
      }

      if (tourId != null &&
          nextRoute?['End Arrived'] == false &&
          currentDate.isAfter(
            tourStartDate.subtract(const Duration(hours: 2, minutes: 30)),
          ) &&
          currentDate.isBefore(tourEndDate.add(const Duration(hours: 1)))) {
        FirebaseApi.instance.scheduleTourReminders(tourStartDate, tourId);
      }

      if (tourId != null &&
          (nextRoute?['onRoad'] == true || nextRoute?['End Arrived'] == true)) {
        FirebaseApi.instance.cancelTourReminders(tourId);
      }
    });

    final rideState = ref.watch(rideProvider);
    final selectedIndex = ref.watch(selectedIndexProvider);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final index = ref.watch(selectedIndexProvider);

    final currentDate = DateTime.now();
    final tourStartDate = parseDate(rideState.nextRoute?['StartDate']);
    final tourEndDate = parseDate(rideState.nextRoute?['EndDate']);
    final endArrived = rideState.nextRoute?["End Arrived"];

    final bool isTourStarted =
        endArrived == false &&
        currentDate.isAfter(tourStartDate.subtract(const Duration(hours: 2))) &&
        currentDate.isBefore(tourEndDate.add(const Duration(hours: 1)));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.075),
        child: BuildAppBar(),
      ),
      body: listNavBar[selectedIndex],
      bottomNavigationBar: BottomNavBar(),

      floatingActionButton:
          isTourStarted
              ? index == 0
                  ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    child: SizedBox(
                      width: width * 0.5,
                      height: height * 0.07,
                      child: Material(
                        elevation: width * 0.02,
                        borderRadius: BorderRadius.circular(width * 0.045),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(width * 0.045),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RidePage(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                width * 0.045,
                              ),
                              gradient: LinearGradient(
                                colors:
                                    darkMode
                                        ? [Color(0xFF34A8EB), Color(0xFF015E9C)]
                                        : [
                                          Color(0xFF34A8EB),
                                          Color(0xFF015E9C),
                                        ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: width * 0.02),
                                  Text(
                                    'Start Ride',
                                    style: GoogleFonts.cabin(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.05,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  : null
              : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
    );
  }
}
