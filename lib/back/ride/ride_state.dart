import 'dart:async';

import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/map_and_location/get_functions.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver_app/front/tools/ride_model.dart';
import 'package:driver_app/front/tools/get_location_name.dart';
import 'package:latlong2/latlong.dart';

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
  RideNotifier() : super(RideState()) {
    fetchRides();
  }

  StreamSubscription<QuerySnapshot>? carsSubscription;
  Timer? locationTrackingTImer;

  Future<void> fetchRides() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    carsSubscription = FirebaseFirestore.instance
        .collection('Cars')
        .snapshots()
        .listen((snapshot) {
          final allRides =
              snapshot.docs
                  .map(
                    (doc) => Ride.fromFirestore(data: doc.data(), id: doc.id),
                  )
                  .toList();

          final filtered =
              allRides.where((ride) => ride.driver == userId).toList();
          final updatedRides = <Map<String, dynamic>>[];

          for (var ride in filtered) {
            ride.routes.forEach((key, route) {
              final routeDate = (route['StartDate'] as Timestamp).toDate();
              final routeEndDate = (route['EndDate'] as Timestamp).toDate();
              final now = DateTime(2025, 02, 17, 15, 27);
              final startArrived = route["Start Arrived"] as bool;
              final endArrived = route["End Arrived"] as bool;
              if (now.isAfter(routeDate.subtract(Duration(hours: 1))) &&
                  now.isBefore(routeEndDate.add(Duration(hours: 5))) &&
                  (!startArrived || !endArrived)) {
                final routeWithKey = Map<String, dynamic>.from(route);
                routeWithKey['routeKey'] = key;
                updatedRides.add(routeWithKey);
              }
            });
            logger.d(updatedRides);
          }

          state = state.copyWith(
            filteredRides: filtered,
            currentRides: updatedRides,
          );

          _updateNextRoute(updatedRides);
        });
  }

  Future<void> _updateNextRoute(List<Map<String, dynamic>> currentRides) async {
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

    final currentNext = state.nextRoute;
    final isNewRoute =
        currentNext == null || currentNext['ID'] != newNext['ID'];
    final startArrivedChanged =
        currentNext?['Start Arrived'] != newNext['Start Arrived'];
    final endArrivedChanged =
        currentNext?['End Arrived'] != newNext['End Arrived'];

    if (isNewRoute || startArrivedChanged || endArrivedChanged) {
      final routeKey = newNext['routeKey'] as String;
      final docId = newNext['ID'];

      final startLatLngSplit = newNext['Start'].split(',');
      final startLatLng = LatLng(
        double.parse(startLatLngSplit[0]),
        double.parse(startLatLngSplit[1]),
      );
      final endLatLngSplit = newNext['End'].split(',');
      final endLatLng = LatLng(
        double.parse(endLatLngSplit[0]),
        double.parse(endLatLngSplit[1]),
      );

      final startLocationName = await getLocationName(
        startLatLng.latitude,
        startLatLng.longitude,
      );
      final endLocationName = await getLocationName(
        endLatLng.latitude,
        endLatLng.longitude,
      );

      state = state.copyWith(
        nextRoute: newNext,
        routeKey: routeKey,
        docId: docId,
        startLatLng: startLatLng,
        endLatLng: endLatLng,
        startLocationName: startLocationName,
        endLocationName: endLocationName,
        startArrived: newNext["Start Arrived"],
        endArrived: newNext["End Arrived"],
      );

      startLocationTrackingLoop();
    }
  }

  void startLocationTrackingLoop() {
    locationTrackingTImer?.cancel();
    locationTrackingTImer = Timer.periodic(Duration(seconds: 5), (_) async {
      final next = state.nextRoute;
      if (next == null) return;
      final startDate = (next['StartDate'] as Timestamp).toDate();
      final now = DateTime(2025, 02, 17, 15, 36);
      if (now.isAfter(startDate.subtract(Duration(hours: 1)))) {
        final startArrived = next['Start Arrived'] as bool;
        final endArrived = next['End Arrived'] as bool;
        if (!startArrived && !endArrived) {
          await initializeService();
        } else if (startArrived && endArrived) {
          await fetchRides();
        } else {
          locationTrackingTImer?.cancel();
          final service = FlutterBackgroundService();
          service.invoke("stopService");
        }
      }
    });
  }

  @override
  void dispose() {
    carsSubscription?.cancel();
    locationTrackingTImer?.cancel();
    FlutterBackgroundService().invoke("stopService");
    super.dispose();
  }
}

final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  return RideNotifier();
});
