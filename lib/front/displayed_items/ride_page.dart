import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/map_and_location/get_functions.dart';
import 'package:driver_app/front/tools/consts.dart';
import 'package:driver_app/front/tools/ride_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

Timer? _timer;

class RidePage extends StatefulWidget {
  const RidePage({super.key});

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  StreamSubscription<QuerySnapshot>? carsSubscription;
  Map<String, dynamic>? userData;
  List<Ride> filteredRides = [];
  List<Map<String, dynamic>> currentRides = [];
  Map<String, dynamic>? nextRoute;

  LocationData? startLatLngObj;
  LatLng? currentLocation;
  LatLng? endLatLngObj;
  double? speedMps;

  GoogleMapController? mapController;
  Map<PolylineId, Polyline> polylines = {};
  CameraPosition? initialCameraPosition;
  late String _mapStyleString;
  Location locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;
  Set<Marker> markers = {};

  void customMarker() {
    BitmapDescriptor.asset(
      ImageConfiguration(size: Size(50, 40)),
      'assets/Car.png',
    ).then((icon) {
      setState(() {
        customIcon = icon;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    customMarker();
    DefaultAssetBundle.of(context).loadString('assets/map_style.json').then((
      value,
    ) {
      setState(() {
        _mapStyleString = value;
      });
    });

    getLocationUpdates(
      locationController: locationController,
      onLocationUpdate: (position) {
        if (mounted) {
          setState(() {
            startLatLngObj = position;
            speedMps = position.speedAccuracy! * 3.6;
            currentLocation = LatLng(
              startLatLngObj!.latitude!,
              startLatLngObj!.longitude!,
            );
          });
        }

        var mid = MarkerId('start_location');
        var newPosition = LatLng(
          currentLocation!.latitude,
          currentLocation!.longitude,
        );

        markers = {
          Marker(
            markerId: mid,
            position: newPosition,
            icon: customIcon,
            anchor: const Offset(0.5, 0.5),
            rotation: startLatLngObj!.heading!,
          ),
        };

        if (startLatLngObj != null && endLatLngObj != null) {
          updateMapZoom();
          cameraToPosition(
            mapController: _mapController,
            position: currentLocation!,
          );

          getPolyLinePoints(
            googleApiKey: GOOGLE_MAPS_API_KEY,
            source: currentLocation!,
            destination: endLatLngObj!,
          ).then((coordinates) {
            if (coordinates.isNotEmpty) {
              final polylineId = PolylineId('main_route');
              final Polyline polyline = Polyline(
                polylineId: polylineId,
                color: Colors.blue,
                width: 5,
                points: coordinates,
              );

              setState(() {
                polylines[polylineId] = polyline;
              });
            } else {
              logger.e('Failed to fetch polyline coordinates');
            }
          });
        }
      },
    );
    fetchUserData();
  }

  LatLng getMidpoint(LatLng? start, LatLng? end) {
    if (start == null || end == null) {
      return const LatLng(0.0, 0.0);
    }
    double midLat = (start.latitude + end.latitude) / 2;
    double midLng = (start.longitude + end.longitude) / 2;

    return LatLng(midLat, midLng);
  }

  Future<void> fetchUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .get();
        if (docSnapshot.exists) {
          setState(() {
            userData = docSnapshot.data();
          });
          fetchAndFilterRides(userData: userData!);
        }
      }
    } catch (e) {
      logger.e('Error fetching user\'s data: $e');
    }
  }

  Future<void> fetchAndFilterRides({
    required Map<String, dynamic> userData,
  }) async {
    carsSubscription = FirebaseFirestore.instance
        .collection('Cars')
        .snapshots()
        .listen((querySnapshot) {
          final allRides =
              querySnapshot.docs.map((doc) {
                return Ride.fromFirestore(data: doc.data(), id: doc.id);
              }).toList();
          final userId = FirebaseAuth.instance.currentUser?.uid;
          final filtered =
              allRides.where((ride) {
                return ride.driver == userId;
              }).toList();

          setState(() {
            filteredRides = filtered;
          });
          getCurrentDateRides(filteredRides);
        });
  }

  void getCurrentDateRides(List<Ride> rides) {
    final List<Map<String, dynamic>> updatedRides = [];
    for (int i = 0; i < filteredRides.length; i++) {
      filteredRides[i].routes.forEach((key, route) {
        final Timestamp fetchedStartDate = route['StartDate'];
        final tourStartDate = fetchedStartDate.toDate();
        final startDate = DateTime(
          tourStartDate.year,
          tourStartDate.month,
          tourStartDate.day,
        );
        final currentDateTime = DateTime(2025, 01, 13);
        final currentDate = DateTime(
          currentDateTime.year,
          currentDateTime.month,
          currentDateTime.day,
        );

        if (startDate.isAtSameMomentAs(currentDate)) {
          updatedRides.add(route);
        }
      });
      setState(() {
        currentRides = updatedRides;
        updateNextRoute();
      });
    }
  }

  void updateNextRoute() {
    if (currentRides.isEmpty) {
      setState(() {
        nextRoute = null;
      });
      return;
    }

    nextRoute = currentRides.firstWhere(
      (route) =>
          !(route["Start Arrived"] as bool) || !(route["End Arrived"] as bool),
      orElse: () => {},
    );

    if (nextRoute != null) {
      String endCoordinates =
          nextRoute!['Start Arrived'] == false
              ? nextRoute!['Start']
              : nextRoute!['End'];
      List<String> endLatLng = endCoordinates.split(",");
      double endLat = double.parse(endLatLng[0]);
      double endLng = double.parse(endLatLng[1]);
      setState(() {
        endLatLngObj = LatLng(endLat, endLng);
      });
    }
  }

  double getZoomLevel(double distanceInMeters) {
    double zoomLevel = 15.0;

    if (distanceInMeters < 500) {
      zoomLevel = 16.0;
    } else if (distanceInMeters < 1000) {
      zoomLevel = 14.0;
    } else if (distanceInMeters < 5000) {
      zoomLevel = 12.0;
    } else {
      zoomLevel = 10.0;
    }

    return zoomLevel;
  }

  void updateMapZoom() {
    if (startLatLngObj != null && endLatLngObj != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        endLatLngObj!.latitude,
        endLatLngObj!.longitude,
      );

      double zoomLevel = getZoomLevel(distanceInMeters);

      LatLng midpoint = getMidpoint(currentLocation, endLatLngObj);

      initialCameraPosition = CameraPosition(target: midpoint, zoom: zoomLevel);
    }
  }

  @override
  void dispose() {
    carsSubscription?.cancel();
    if (mapController != null) {
      mapController!.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (startLatLngObj == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child:
              nextRoute != null
                  ? Stack(
                    children: [
                      SizedBox(
                        child: GoogleMap(
                          initialCameraPosition:
                              initialCameraPosition ??
                              CameraPosition(
                                target: currentLocation!,
                                zoom: 15,
                              ),
                          zoomControlsEnabled: false,

                          mapType: MapType.normal,
                          trafficEnabled: true,
                          style: _mapStyleString,

                          tiltGesturesEnabled: true,
                          markers: markers,

                          polylines: Set<Polyline>.of(polylines.values),
                        ),
                      ),

                      Text('$speedMps'),
                    ],
                  )
                  : const Text('No routes available for Today'),
        ),
      ),
    );
  }
}
