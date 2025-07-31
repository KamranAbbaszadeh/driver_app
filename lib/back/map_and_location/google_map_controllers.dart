// Utility functions for handling Google Maps polyline generation.
// Includes logic to fetch and draw routes between two coordinates using the Google Directions API.
import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Fetches a list of LatLng points representing a route from [source] to [destination]
/// using the Google Directions API via [flutter_polyline_points].
/// Returns an empty list if no points are found.
Future<List<LatLng>> getPolyLinePoints({
  required String googleApiKey,
  required LatLng source,
  required LatLng destination,
}) async {
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKey);

  RoutesApiRequest request = RoutesApiRequest(
    origin: PointLatLng(source.latitude, source.longitude),
    destination: PointLatLng(destination.latitude, destination.longitude),
    travelMode: TravelMode.driving,
    routingPreference: RoutingPreference.trafficAware,
  );
  RoutesApiResponse polylineResult = await polylinePoints
      .getRouteBetweenCoordinatesV2(request: request);

  if (polylineResult.routes.isNotEmpty) {
    for (final route in polylineResult.routes) {
      if (route.polylinePoints != null) {
        for (final point in route.polylinePoints!) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      }
    }
  }

  return polylineCoordinates;
}

/// Generates a Polyline from the provided [polylineCoordinates] and adds it to the map.
/// The [updatePolylines] callback is used to trigger a rebuild with the new Polyline.
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
