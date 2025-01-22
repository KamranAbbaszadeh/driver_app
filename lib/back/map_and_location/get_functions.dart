import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';

Future<void> getLocationUpdates({
  required Location locationController,
  required Function(LocationData) onLocationUpdate,
}) async {
  bool serviceEnabled;
  PermissionStatus permissionGranted;

  serviceEnabled = await locationController.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await locationController.requestService();
    if (!serviceEnabled) return;
  }

  permissionGranted = await locationController.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await locationController.requestPermission();
    if (permissionGranted != PermissionStatus.granted) return;
  }

  locationController.onLocationChanged.listen((LocationData currentLocation) {
    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      onLocationUpdate(
        currentLocation,
      );
    }
  });
}

Future<List<LatLng>> getPolyLinePoints({
  required String googleApiKey,
  required LatLng source,
  required LatLng destination,
}) async {
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  PolylineResult polylineResult = await polylinePoints
      .getRouteBetweenCoordinates(
        googleApiKey: googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(source.latitude, source.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

  if (polylineResult.points.isNotEmpty) {
    for (PointLatLng point in polylineResult.points) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }
  }
  return polylineCoordinates;
}

void generatePolyLineFromPoints({
  required List<LatLng> polylineCoordinates,
  required Map<PolylineId, Polyline> polylines,
  required Function(Map<PolylineId, Polyline>) updatePolylines,
}) {
  PolylineId id = PolylineId('poly');
  Polyline polyLine = Polyline(
    polylineId: id,
    color: const Color.fromARGB(183, 139, 2, 2),
    points: polylineCoordinates,
    width: 8,
  );
  polylines[id] = polyLine;
  updatePolylines(polylines);
}

Future<void> cameraToPosition({
  required Completer<GoogleMapController> mapController,
  required LatLng position,
}) async {
  final GoogleMapController controller = await mapController.future;
  CameraPosition newCameraPosition = CameraPosition(target: position, zoom: 15);
  controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
}
