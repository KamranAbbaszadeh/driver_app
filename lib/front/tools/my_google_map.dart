import 'dart:async';

import 'package:driver_app/back/map_and_location/get_functions.dart';
import 'package:driver_app/front/tools/consts.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MyGoogleMap extends StatefulWidget {
  const MyGoogleMap({super.key});

  @override
  State<MyGoogleMap> createState() => _MyGoogleMapState();
}

class _MyGoogleMapState extends State<MyGoogleMap> {
  Location locationController = Location();

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  static const LatLng _pGooglePlex = LatLng(40.39063, 49.89154);
  static const LatLng _pApplePark = LatLng(40.37577, 49.86025);
  LatLng? currentP;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates(
      locationController: locationController,
      onLocationUpdate: (position) {
        setState(() {
          currentP = LatLng(position.latitude!, position.longitude!);
        });
        cameraToPosition(
          mapController: _mapController,
          position: LatLng(position.latitude!, position.longitude!),
        );
      },
    ).then(
      (_) => getPolyLinePoints(
        googleApiKey: GOOGLE_MAPS_API_KEY,
        source: _pGooglePlex,
        destination: _pApplePark,
      ).then(
        (coordinates) => generatePolyLineFromPoints(
          polylineCoordinates: coordinates,
          polylines: polylines,
          updatePolylines: (updatedPolylines) {
            setState(() {
              polylines = updatedPolylines;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          currentP == null
              ? const Center(child: Text('Loading...'))
              : SafeArea(
                child: GoogleMap(
                  onMapCreated:
                      (GoogleMapController controller) =>
                          _mapController.complete(controller),
                  initialCameraPosition: CameraPosition(
                    target: _pGooglePlex,
                    zoom: 13,
                  ),
                  mapType: MapType.normal,
                  trafficEnabled: true,
                  indoorViewEnabled: true,
                  mapToolbarEnabled: true,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  zoomControlsEnabled: true,
                  markers: {
                    Marker(
                      markerId: MarkerId('_currentLocation'),
                      icon: BitmapDescriptor.defaultMarker,
                      position: currentP!,
                    ),
                    Marker(
                      markerId: MarkerId('_sourceLocation'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                      position: _pGooglePlex,
                    ),
                    Marker(
                      markerId: MarkerId('_destinationLocation'),
                      icon: BitmapDescriptor.defaultMarker,
                      position: _pApplePark,
                    ),
                  },
                  polylines: Set<Polyline>.of(polylines.values),
                ),
              ),
    );
  }
}
