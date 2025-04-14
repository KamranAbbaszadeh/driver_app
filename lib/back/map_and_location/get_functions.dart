import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
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
                        top: height * 0.028,
                        left: width * 0.061,
                        right: width * 0.061,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: width * 0.061,
                        vertical: height * 0.014,
                      ),
                      actionsPadding: EdgeInsets.only(
                        bottom: height * 0.014,
                        right: width * 0.03,
                      ),
                      title: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color:
                                darkMode
                                    ? Color.fromARGB(255, 52, 168, 235)
                                    : Color.fromARGB(255, 1, 105, 170),
                          ),
                          SizedBox(width: width * 0.03),
                          Expanded(
                            child: Text(
                              "Enable Background Location",
                              style: GoogleFonts.cabin(
                                fontWeight: FontWeight.w600,
                                fontSize: width * 0.04,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: Text.rich(
                        TextSpan(
                          text: "This app needs location access ",
                          style: GoogleFonts.cabin(fontSize: 15),
                          children: [
                            TextSpan(
                              text: "all the time",
                              style: GoogleFonts.cabin(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.04,
                              ),
                            ),
                            TextSpan(
                              text:
                                  " to accurately track your runs in the background. Please allow ",
                            ),
                            TextSpan(
                              text: "\"Allow all the time\"",
                              style: GoogleFonts.gothicA1(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  " location permission in your device settings.",
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: width * 0.04),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            "Not Now",
                            style: GoogleFonts.cabin(
                              color: darkMode ? Colors.white : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          icon: Icon(Icons.settings),
                          label: Text(
                            "Open Settings",
                            style: GoogleFonts.cabin(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                darkMode
                                    ? Color.fromARGB(255, 52, 168, 235)
                                    : Color.fromARGB(255, 1, 105, 170),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(width * 0.02),
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
                borderRadius: BorderRadius.circular(width * 0.04),
              ),
              titlePadding: EdgeInsets.only(
                top: height * 0.025,
                left: width * 0.061,
                right: width * 0.061,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: width * 0.061,
                vertical: height * 0.018,
              ),
              actionsPadding: EdgeInsets.only(
                bottom: height * 0.014,
                right: width * 0.03,
              ),
              title: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.blue),
                  SizedBox(width: width * 0.025),
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
                style: TextStyle(fontSize: width * 0.038),
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
