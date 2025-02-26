import 'dart:async';
import 'dart:io';

import 'package:driver_app/back/api/firebase_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

Future<void> getLocationUpdates({
  required Function(Position) onLocationUpdate,
  required BuildContext context,
}) async {
  await requestLocationPermission(context: context);

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openAppSettings();
    return Future.error('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.',
    );
  }

  void updateSpeed() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      onLocationUpdate(position);
    });
  }

  await FlutterForegroundTask.startService(
    notificationTitle: "Tracking Speed",
    notificationText: "App is running in the background",
    callback: updateSpeed,
  );

  void backgroundSpeedTracking() {
    Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          ),
        )
        .then((Position position) {
          onLocationUpdate(position);
        })
        .catchError((e) {
          logger.e("Error getting location: $e");
        });
  }

  @pragma('vm:entry-point')
  void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) {
      backgroundSpeedTracking();
      return Future.value(true);
    });
  }

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  Platform.isIOS
      ? Workmanager().registerOneOffTask(
        'speed_tracking_task',
        'tracking_speed',
        initialDelay: Duration(minutes: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,

          requiresCharging: true,
        ),
        inputData: <String, dynamic>{},
      )
      : null;

  Workmanager().registerPeriodicTask(
    'speed_tracking_task',
    'tracking_speed',
    inputData: <String, dynamic>{},
    frequency: Duration(seconds: 10),
  );
}

Future<void> requestLocationPermission({required context}) async {
  var status = await Permission.location.status;
  if (status.isDenied) {
    await Permission.location.request();
  }
  if (await Permission.locationAlways.isDenied) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Location Permission'),
            content: Text(
              'Please allow All The Time location permission to use this app.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Permission.locationAlways.request();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  if (status.isPermanentlyDenied) {
    await openAppSettings();
  }
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
  required LocationData currentPosition,
  required bool isStarted,
  required LatLng mid,
  required double zoom,
  required bool isUserInteracting,
  required ValueNotifier<bool> isAnimatingCamera,
}) async {
  if (isAnimatingCamera.value) {
    return;
  }

  if (!mapController.isCompleted) {
    return;
  }

  final GoogleMapController controller = await mapController.future;

  if (isUserInteracting && !isStarted) {
    return;
  }

  isAnimatingCamera.value = true;

  try {
    if (isStarted) {
      CameraPosition newCameraPosition = CameraPosition(
        target: position,
        zoom: 15,
        tilt: 45,
        bearing: currentPosition.heading ?? 0,
      );
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(newCameraPosition),
      );
    }
    if (!isStarted) {
      CameraPosition cameraPosition = CameraPosition(
        target: mid,
        zoom: zoom,
        bearing: 0,
        tilt: 0,
      );
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  } catch (e, stackTrace) {
    debugPrint("Error animating camera: $e, StackTrace: $stackTrace");
  } finally {
    isAnimatingCamera.value = false;
  }
}
