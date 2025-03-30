import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'location_tracking',
      initialNotificationTitle: 'Location Tracking',
      initialNotificationContent: 'Tracking your location in background',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: (_) async => true,
    ),
  );

  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Location Tracking",
      content: "Tracking your location in background",
    );
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isServiceEnabled) {
    service.invoke('LocationServiceDisabled');
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse) {
    LatLng? previousLocation;
    DateTime? previousTimestamp;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      String currentSpeed = "0";
      final newLocation = LatLng(position.latitude, position.longitude);
      final newTimestamp = position.timestamp;

      double finalSpeed = 0;

      if (previousTimestamp != null && previousLocation != null) {
        final timeDiffMillis =
            newTimestamp.difference(previousTimestamp!).inMilliseconds;

        if (timeDiffMillis > 0) {
          final distance = Geolocator.distanceBetween(
            previousLocation!.latitude,
            previousLocation!.longitude,
            newLocation.latitude,
            newLocation.longitude,
          );

          if (distance >= 10) {
            final calculatedSpeed = distance / (timeDiffMillis / 1000);
            finalSpeed = calculatedSpeed;
            previousLocation = newLocation;
            previousTimestamp = newTimestamp;
          }
        }
      } else {
        previousLocation = newLocation;
        previousTimestamp = newTimestamp;
      }
      if (finalSpeed > 0) {
        currentSpeed = (finalSpeed * 3.6).toStringAsFixed(0);
      } else {
        currentSpeed = "0";
      }
      service.invoke('LocationUpdates', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timeStamp': position.timestamp.toIso8601String(),
        'speed': currentSpeed,
        'heading': position.heading,
      });
    });
  }
}

Future<void> requestLocationPermissions(BuildContext context) async {
  PermissionStatus foregroundStatus =
      await Permission.locationWhenInUse.request();
  if (foregroundStatus.isGranted) {
    PermissionStatus backgroundStatus = await Permission.locationAlways.status;
    if (backgroundStatus.isGranted) {
      return;
    }
    bool shouldOpenSettings =
        context.mounted
            ? await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      titlePadding: EdgeInsets.only(
                        top: 24,
                        left: 24,
                        right: 24,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      actionsPadding: EdgeInsets.only(bottom: 12, right: 12),
                      title: Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Enable Background Location",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      content: Text.rich(
                        TextSpan(
                          text: "This app needs location access ",
                          children: [
                            TextSpan(
                              text: "all the time",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  " to accurately track your runs in the background. Please allow ",
                            ),
                            TextSpan(
                              text: "\"Always\"",
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            TextSpan(
                              text:
                                  " location permission in your device settings.",
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 15),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text("Not Now"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          icon: Icon(Icons.settings),
                          label: Text("Open Settings"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ) ??
                false
            : false;

    if (shouldOpenSettings) {
      await Permission.locationAlways.request();
    }
  } else {
    if (foregroundStatus.isPermanentlyDenied && context.mounted) {
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
              title: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Location Permission Needed",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              content: Text.rich(
                TextSpan(
                  text:
                      "To function properly, this app needs location access. ",
                  children: [
                    TextSpan(text: "Please enable location permission "),
                    TextSpan(
                      text: "in your app settings.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
      );
      openAppSettings();
    }
  }
}
