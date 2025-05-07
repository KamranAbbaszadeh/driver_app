import 'dart:async';

import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/map_and_location/location_provider.dart';
import 'package:driver_app/back/map_and_location/ride_flow_provider.dart';
import 'package:driver_app/back/ride/ride_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideMap extends ConsumerStatefulWidget {
  const RideMap({super.key});

  @override
  ConsumerState<RideMap> createState() => _RideMapState();
}

class _RideMapState extends ConsumerState<RideMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  CameraPosition? _initialCameraPosition;
  BitmapDescriptor? _currentIcon;
  late String _mapStyleDarkString;
  late String _mapStyleLightString;
  late double screenWidth;
  late double screenHeight;

  @override
  void initState() {
    super.initState();

    // rideFlowProvider listener
    ref.listenManual(rideFlowProvider, (previous, next) {
      if (next.startRide) {
        final position = ref.read(locationProvider);
        if (position != null && _mapController != null) {
          final currentLatLng = LatLng(
            position['latitude'],
            position['longitude'],
          );
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: currentLatLng, zoom: 16.0),
            ),
          );
        }
      }
    });

    // locationProvider listener
    ref.listenManual(locationProvider, (previous, next) {
      if (next != null && _mapController != null) {
        final updatedLatLng = LatLng(next['latitude'], next['longitude']);
        final heading = next['heading']?.toDouble() ?? 0.0;
        _updateCurrentLocationMarker(updatedLatLng, heading);
      }
    });
  }

  void _updateCurrentLocationMarker(LatLng position, double heading) {
    setState(() {
      _markers = {
        ..._markers.where((m) => m.markerId.value != 'current'),
        Marker(
          markerId: const MarkerId('current'),
          position: position,
          icon: _currentIcon ?? BitmapDescriptor.defaultMarker,
          rotation: heading,
          anchor: const Offset(0.5, 0.5),
        ),
      };
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;
    DefaultAssetBundle.of(
      context,
    ).loadString('assets/map_style_dark.json').then((value) {
      setState(() {
        _mapStyleDarkString = value;
      });
    });

    DefaultAssetBundle.of(
      context,
    ).loadString('assets/map_style_light.json').then((value) {
      setState(() {
        _mapStyleLightString = value;
      });
    });
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final position = ref.read(locationProvider);
    final rideState = ref.read(rideProvider);
    final startLatLng = rideState.startLatLng;
    final endLatLng = rideState.endLatLng;

    if (position == null || startLatLng == null || endLatLng == null) return;

    final currentLocation = LatLng(position['latitude'], position['longitude']);
    logger.d(currentLocation);
    final midPoint = getMidpoint(startLatLng, endLatLng, currentLocation);
    final distance = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      endLatLng.latitude,
      endLatLng.longitude,
    );
    final zoomLvl = getZoomLevel(distance);

    final BitmapDescriptor startIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(screenWidth * 0.122, screenHeight * 0.056)),
      'assets/start_location.png',
    );
    final BitmapDescriptor endIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(screenWidth * 0.122, screenHeight * 0.056)),
      'assets/end_location.png',
    );
    final BitmapDescriptor currentIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(screenWidth * 0.122, screenHeight * 0.056)),
      'assets/car_icons/arrow.png',
    );
    _currentIcon = currentIcon;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('start'),
          infoWindow: InfoWindow(title: rideState.startLocationName),
          position: startLatLng,
          icon: startIcon,
        ),
        Marker(
          markerId: const MarkerId('end'),
          infoWindow: InfoWindow(title: rideState.endLocationName),
          position: endLatLng,
          icon: endIcon,
        ),
        Marker(
          markerId: const MarkerId('current'),
          position: currentLocation,
          icon: currentIcon,
          rotation: position['heading']?.toDouble() ?? 0.0,
          anchor: const Offset(0.5, 0.5),
        ),
      };
      try {
        _initialCameraPosition = CameraPosition(
          target: midPoint,
          zoom: zoomLvl,
        );
      } catch (e) {
        logger.e('Error setting initial camera position: $e');
      }
    });
    final rideFlow = ref.read(rideFlowProvider);
    if (rideFlow.startRide && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocation, zoom: 16.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_initialCameraPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialCameraPosition!,
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
          },

          style: darkMode ? _mapStyleDarkString : _mapStyleLightString,
          fortyFiveDegreeImageryEnabled: false,
          trafficEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          buildingsEnabled: true,
          mapType: MapType.normal,
        ),
        Positioned(
          bottom: height * 0.093,
          right: width * 0.04,
          child: FloatingActionButton(
            heroTag: 'map_location_btn',
            backgroundColor: Colors.white,
            onPressed: () {
              final rideFlow = ref.read(rideFlowProvider);
              final position = ref.read(locationProvider);

              if (_mapController != null) {
                if (rideFlow.startRide && position != null) {
                  final currentLatLng = LatLng(
                    position['latitude'],
                    position['longitude'],
                  );
                  _mapController!.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: currentLatLng, zoom: 16.0),
                    ),
                  );
                } else if (_initialCameraPosition != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newCameraPosition(_initialCameraPosition!),
                  );
                }
              }
            },
            child: const Icon(Icons.my_location, color: Colors.black),
          ),
        ),
      ],
    );
  }

  LatLng getMidpoint(LatLng? start, LatLng? end, LatLng? current) {
    if (start == null || end == null || current == null) {
      return const LatLng(0.0, 0.0);
    }
    double midLat = (start.latitude + end.latitude + current.latitude) / 3;
    double midLng = (start.longitude + end.longitude + current.longitude) / 3;
    return LatLng(midLat, midLng);
  }

  double getZoomLevel(double distanceInMeters) {
    if (distanceInMeters < 500) return 16.0;
    if (distanceInMeters < 1000) return 12.0;
    if (distanceInMeters < 5000) return 10.0;
    return 8.0;
  }
}
