import 'dart:async';

import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/map_and_location/get_functions.dart';
import 'package:driver_app/back/map_and_location/location_post_api.dart';
import 'package:driver_app/back/map_and_location/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver_app/front/tools/ride_model.dart';
import 'package:driver_app/front/tools/get_location_name.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

class RideState {
  final List<Ride> filteredRides;
  final List<Map<String, dynamic>> currentRides;
  final Map<String, dynamic>? nextRoute;
  final String? docId;
  final String? routeKey;
  final LatLng? startLatLng;
  final LatLng? endLatLng;
  final String? startLocationName;
  final String? endLocationName;
  final bool? startArrived;
  final bool? endArrived;

  RideState({
    this.filteredRides = const [],
    this.currentRides = const [],
    this.nextRoute,
    this.docId,
    this.routeKey,
    this.startLatLng,
    this.endLatLng,
    this.startLocationName,
    this.endLocationName,
    this.startArrived,
    this.endArrived,
  });

  RideState copyWith({
    List<Ride>? filteredRides,
    List<Map<String, dynamic>>? currentRides,
    Map<String, dynamic>? nextRoute,
    String? docId,
    String? routeKey,
    LatLng? startLatLng,
    LatLng? endLatLng,
    String? startLocationName,
    String? endLocationName,
    bool? startArrived,
    bool? endArrived,
  }) {
    return RideState(
      filteredRides: filteredRides ?? this.filteredRides,
      currentRides: currentRides ?? this.currentRides,
      nextRoute: nextRoute ?? this.nextRoute,
      docId: docId ?? this.docId,
      routeKey: routeKey ?? this.routeKey,
      startLatLng: startLatLng ?? this.startLatLng,
      endLatLng: endLatLng ?? this.endLatLng,
      startLocationName: startLocationName ?? this.startLocationName,
      endLocationName: endLocationName ?? this.endLocationName,
      startArrived: startArrived ?? this.startArrived,
      endArrived: endArrived ?? this.endArrived,
    );
  }
}

class RideNotifier extends StateNotifier<RideState> {
  Timer? _refreshTimer;
  final Ref ref;
  final BuildContext context;

  RideNotifier(this.ref, this.context) : super(RideState()) {
    _startListeningToRides();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {});
  }

  StreamSubscription<QuerySnapshot>? carsSubscription;
  Timer? locationTrackingTImer;

  void _startListeningToRides() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    FirebaseFirestore.instance.collection('Users').doc(userId).get().then((
      userDoc,
    ) {
      final role = userDoc.data()?['Role'] ?? '';

      final streams = <Stream<QuerySnapshot>>[];

      if (role == 'Guide') {
        streams.add(FirebaseFirestore.instance.collection('Guide').snapshots());
      } else if (role == 'Driver Cum Guide') {
        streams.add(FirebaseFirestore.instance.collection('Cars').snapshots());
        streams.add(FirebaseFirestore.instance.collection('Guide').snapshots());
      } else {
        streams.add(FirebaseFirestore.instance.collection('Cars').snapshots());
      }

      for (final stream in streams) {
        stream.listen((snapshot) {
          final allRides =
              snapshot.docs.map((doc) {
                return Ride.fromFirestore(
                  data: doc.data() as Map<String, dynamic>,
                  id: doc.id,
                );
              }).toList();

          final filtered =
              allRides.where((ride) {
                if (role == 'Guide') {
                  return ride.guide == userId;
                } else if (role == 'Driver') {
                  return ride.driver == userId;
                }
                return ride.driver == userId || ride.guide == userId;
              }).toList();

          final updatedRides = <Map<String, dynamic>>[];

          for (var ride in filtered) {
            ride.routes.forEach((key, route) {
              final routeWithKey = Map<String, dynamic>.from(route);
              routeWithKey['routeKey'] = key;
              updatedRides.add(routeWithKey);
            });
          }

          if (state.filteredRides != filtered ||
              state.currentRides != updatedRides) {
            state = state.copyWith(
              filteredRides: filtered,
              currentRides: updatedRides,
            );
          }

          if (context.mounted) {
            updateNextRoute(updatedRides, context);
          }
        });
      }
    });
  }

  Future<void> updateNextRoute(
    List<Map<String, dynamic>> currentRides,
    BuildContext context,
  ) async {
    if (currentRides.isEmpty) {
      state = state.copyWith(nextRoute: null);
      return;
    }

    final newNext = currentRides.firstWhere(
      (route) =>
          !(route["Start Arrived"] as bool) || !(route["End Arrived"] as bool),
      orElse: () => {},
    );

    if (newNext.isEmpty) {
      if (state.nextRoute != null) {
        state = state.copyWith(nextRoute: null);
      }
      return;
    }

    if (MapEquality().equals(state.nextRoute, newNext)) return;

    final currentNext = state.nextRoute;
    final isNewRoute =
        currentNext == null || currentNext['ID'] != newNext['ID'];
    final startArrivedChanged =
        currentNext?['Start Arrived'] != newNext['Start Arrived'];
    final endArrivedChanged =
        currentNext?['End Arrived'] != newNext['End Arrived'];
    final currentStart =
        DateTime.tryParse(currentNext?['StartDate'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final currentEnd =
        DateTime.tryParse(currentNext?['EndDate'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final newStart =
        DateTime.tryParse(newNext['StartDate'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final newEnd =
        DateTime.tryParse(newNext['EndDate'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final tourDateChanged = currentStart != newStart || currentEnd != newEnd;

    if (isNewRoute ||
        startArrivedChanged ||
        endArrivedChanged ||
        tourDateChanged) {
      final routeKey = newNext['routeKey'] as String;
      final docId =
          state.filteredRides
              .firstWhere(
                (ride) => ride.routes.containsKey(newNext['routeKey']),
                orElse:
                    () => Ride(
                      tourName: '',
                      category: '',
                      transfer: false,
                      startDate: Timestamp.now(),
                      endDate: Timestamp.now(),
                      numOfGuests: 0,
                      pickUpLocation: const GeoPoint(0, 0),
                      price: 0,
                      routes: {},
                      vehicleType: '',
                      driver: '',
                      docId: '',
                      language: '',
                    ),
              )
              .docId;

      LatLng? startLatLng;
      LatLng? endLatLng;
      String? startLocationName;
      String? endLocationName;

      try {
        final startLatLngSplit = newNext['Start'].split(',');
        startLatLng = LatLng(
          double.parse(startLatLngSplit[0]),
          double.parse(startLatLngSplit[1]),
        );
        startLocationName = await getLocationName(
          startLatLng.latitude,
          startLatLng.longitude,
        );
      } catch (e) {
        startLatLng = const LatLng(0, 0);
        startLocationName = 'Unknown';
      }

      try {
        final endLatLngSplit = newNext['End'].split(',');
        endLatLng = LatLng(
          double.parse(endLatLngSplit[0]),
          double.parse(endLatLngSplit[1]),
        );
        endLocationName = await getLocationName(
          endLatLng.latitude,
          endLatLng.longitude,
        );
      } catch (e) {
        endLatLng = const LatLng(0, 0);
        endLocationName = 'Unknown';
      }

      final updatedNextRoute = Map<String, dynamic>.from(newNext);
      state = state.copyWith(
        nextRoute: updatedNextRoute,
        routeKey: routeKey,
        docId: docId,
        startLatLng: startLatLng,
        endLatLng: endLatLng,
        startLocationName: startLocationName,
        endLocationName: endLocationName,
        startArrived: newNext["Start Arrived"],
        endArrived: newNext["End Arrived"],
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('docId', docId);
      await prefs.setString('startDate', newNext['StartDate'] ?? '');
      await prefs.setString('endDate', newNext['EndDate'] ?? '');
      await prefs.setBool('endArrived', newNext['End Arrived'] ?? true);
    }
    if (newNext.isNotEmpty && context.mounted) {
      startLocationTrackingLoop(context);
    }
  }

  void updateCurrentLocation({
    required latitude,
    required longitude,
    required speedKph,
    required heading,
    required timestamp,
  }) async {
    final locationPostApi = LocationPostApi();
    if (!hasMovedSignificantly(latitude, longitude, 25)) {
      logger.d('[headlessTask] ⏩ Skipped (no significant movement)');
      return;
    }
    try {
      lastLatLng = LatLng(latitude, longitude);
      await locationPostApi.postData({
        "CarID": state.docId,
        "Lat": latitude.toString(),
        "Long": longitude.toString(),
        "Speed": speedKph,
      });
    } catch (e) {
      logger.e('Error: $e');
    }
    ref.read(locationProvider.notifier).state = {
      'latitude': latitude,
      'longitude': longitude,
      'speedKph': speedKph,
      'heading': heading,
      'timestamp': timestamp,
    };
  }

  void startLocationTrackingLoop(BuildContext context) {
    locationTrackingTImer?.cancel();
    locationTrackingTImer = Timer.periodic(Duration(seconds: 5), (_) async {
      final next = state.nextRoute;
      if (next == null || !mounted) return;
      final startDateString = next['StartDate'];
      final endDateString = next['EndDate'];
      final startDate = DateTime.parse(startDateString);
      final endDate = DateTime.parse(endDateString);
      final now = DateTime.now();

      if (now.isAfter(startDate.subtract(Duration(hours: 2))) &&
          now.isBefore(endDate.add(Duration(hours: 5)))) {
        final endArrived = next['End Arrived'] as bool;
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && endArrived == false) {
          if (context.mounted) {
            await initializeForegroundTracking(
              context: context,
              onLocation:
                  ({
                    required heading,
                    required latitude,
                    required longitude,
                    required speedKph,
                    required timestamp,
                  }) => updateCurrentLocation(
                    heading: heading,
                    latitude: latitude,
                    longitude: longitude,
                    speedKph: speedKph,
                    timestamp: timestamp,
                  ),
            );
          } else {
            await initializeBackgroundTracking(
              onLocation:
                  ({
                    required heading,
                    required latitude,
                    required longitude,
                    required speedKph,
                    required timestamp,
                  }) => updateCurrentLocation(
                    heading: heading,
                    latitude: latitude,
                    longitude: longitude,
                    speedKph: speedKph,
                    timestamp: timestamp,
                  ),
            );
          }
        } else {
          _startListeningToRides();
          locationTrackingTImer?.cancel();
          await bg.BackgroundGeolocation.stop();
        }
      } else {
        locationTrackingTImer?.cancel();
        await bg.BackgroundGeolocation.stop();
      }
    });
  }

  @override
  void dispose() {
    carsSubscription?.cancel();
    locationTrackingTImer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  final context = ref.read(appContextProvider);
  return RideNotifier(ref, context);
});

final appContextProvider = Provider<BuildContext>((ref) {
  throw UnimplementedError();
});
