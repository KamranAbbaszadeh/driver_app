import 'dart:async';

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
    requestLocationPermissions(context);
    _locationSubscription = FlutterBackgroundService()
        .on('LocationUpdates')
        .listen((event) {
          if (event != null) {
            ref.read(locationProvider.notifier).state = event;
          }
        });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);
    final selectedIndex = ref.watch(selectedIndexProvider);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final index = ref.watch(selectedIndexProvider);
    final tourStartDateTimeStamp = (rideState.nextRoute?['StartDate']);
    final tourEndDateTimeStamp = (rideState.nextRoute?['EndDate']);
    if (tourStartDateTimeStamp == null || tourEndDateTimeStamp == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final tourStartDate = tourStartDateTimeStamp.toDate();
    final tourEndDate = tourEndDateTimeStamp.toDate();

    final startArrived = rideState.nextRoute?["Start Arrived"] as bool;
    final endArrived = rideState.nextRoute?["End Arrived"] as bool;

    final currentDate = DateTime.now();
    final isTourStarted =
        currentDate.isAfter(tourStartDate.subtract(const Duration(hours: 1))) &&
        currentDate.isBefore(tourEndDate.add(const Duration(hours: 1))) &&
        !startArrived &&
        !endArrived;
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RidePage()),
                        );
                      },
                      child: Container(
                        width: width,
                        height: height * 0.06,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(width * 0.019),
                          color:
                              darkMode
                                  ? Color.fromARGB(255, 52, 168, 235)
                                  : Color.fromARGB(255, 1, 105, 170),
                        ),
                        child: Center(
                          child: Text(
                            'Start Ride',
                            style: GoogleFonts.cabin(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.06,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  : null
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
