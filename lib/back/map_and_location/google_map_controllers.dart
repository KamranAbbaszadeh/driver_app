import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

