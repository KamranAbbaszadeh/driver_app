import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/map_and_location/get_functions.dart';
import 'package:onemoretour/back/ride/active_vehicle_provider.dart';
import 'package:onemoretour/back/ride/ride_state.dart';
import 'package:onemoretour/front/displayed_items/ride_page.dart';
import 'package:onemoretour/front/tools/app_bar.dart';
import 'package:onemoretour/front/tools/bottom_bar_provider.dart';
import 'package:onemoretour/front/tools/bottom_nav_bar.dart';
import 'package:onemoretour/front/tools/list_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onemoretour/front/tools/top_padding_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:collection/collection.dart';

// Main home page for the driver app.
// Initializes wake lock, handles exact alarm permission, sets top padding, listens for ride state changes,
// and shows a floating action button to start a ride when conditions are met.


/// Root widget of the home screen, responsible for displaying content based on navigation bar selection.
/// Manages ride reminder scheduling and shows "Start Ride" button when eligible.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  dynamic get onLocation => null;

  /// Enables wake lock and requests alarm permission after widget initialization.
  @override
  void initState() {
    try {
      super.initState();
      WakelockPlus.enable();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FirebaseApi.instance.checkAndRequestExactAlarmPermission(context);
      });
    } catch (e) {
      logger.e('Error to initialize: $e');
    }
  }

  /// Called when widget dependencies change.
  /// Sets top padding and starts async initialization tasks.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAsyncTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final topPadding = MediaQuery.of(context).padding.top;
      ref.read(topPaddingProvider.notifier).state = topPadding;
    });
  }

  /// Requests location and battery optimization permissions (Android only).
  Future<void> _initAsyncTasks() async {
    if (!mounted) return;
    await requestLocationPermissions(context);
    if (!mounted) return;
    if (!Platform.isAndroid) return;
    await requestIgnoreBatteryOptimizations(context);
  }

  /// Parses different formats into [DateTime] for consistent time comparisons.
  DateTime parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes in ride state and respond to tour timing and status.
    // Schedule or cancel ride reminders accordingly.
    ref.listen<RideState>(rideProvider, (previous, next) {
      final prevRoute = previous?.nextRoute;
      final nextRoute = next.nextRoute;
      final currentDate = DateTime.now();
      final tourStartDate = parseDate(nextRoute?['StartDate']);
      final tourEndDate = parseDate(nextRoute?['EndDate']);
      final tourId = nextRoute?['ID'];

      if (!const DeepCollectionEquality().equals(prevRoute, nextRoute)) {
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

    final selectedIndex = ref.watch(selectedIndexProvider);
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.075),
        child: BuildAppBar(),
      ),
      body: listNavBar[selectedIndex],
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final endArrived = ref.watch(
            rideProvider.select((s) => s.endArrived),
          );
          final rideState = ref.watch(rideProvider);
          final nextRoute = rideState.nextRoute;
          final currentDate = DateTime.now();
          final assignedVehicle = rideState.vehicleRegistrationNumber;
          final selectedVehicleAsync = ref.watch(vehicleDataProvider);

          // Conditionally show "Start Ride" button if user has selected the right vehicle,
          // the ride hasn't ended yet, and the current time is within ride window.
          return selectedVehicleAsync.when(
            data: (vehicleData) {
              final selectedVehicle =
                  vehicleData?['Vehicle Registration Number'] ?? '';
              final tourStartDate = parseDate(nextRoute?['StartDate']);
              final tourEndDate = parseDate(nextRoute?['EndDate']);
              final endArrivedValue =
                  rideState.nextRoute?['End Arrived'] ?? endArrived ?? false;
              final index = ref.watch(selectedIndexProvider);

              final isTourStarted =
                  endArrivedValue == false &&
                  assignedVehicle == selectedVehicle &&
                  currentDate.isAfter(
                    tourStartDate.subtract(const Duration(hours: 2)),
                  ) &&
                  currentDate.isBefore(
                    tourEndDate.add(const Duration(hours: 1)),
                  );
                  
              if (isTourStarted && index == 0) {
                final width = MediaQuery.of(context).size.width;
                final height = MediaQuery.of(context).size.height;
                final darkMode =
                    MediaQuery.of(context).platformBrightness ==
                    Brightness.dark;
                return Padding(
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
                              builder: (context) => const RidePage(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(width * 0.045),
                            gradient: LinearGradient(
                              colors:
                                  darkMode
                                      ? [Color(0xFF34A8EB), Color(0xFF015E9C)]
                                      : [Color(0xFF34A8EB), Color(0xFF015E9C)],
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
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          );
        },
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
    );
  }
}
