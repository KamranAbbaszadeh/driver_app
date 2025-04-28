import 'dart:async';
import 'dart:ui';
import 'package:driver_app/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

bool _isLocationListening = false;
bool _isServiceStarted = false;
StreamSubscription<Position>? _positionStream;
Completer<void>? stopCompleter;

Future<void> initializeService() async {
  await requestLocationPermissions(navigatorKey.currentContext!);
  if (_isServiceStarted || _isLocationListening) {
    debugPrint('Skipping service start — already running');
    return;
  }
  _isServiceStarted = true;
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (isRunning) {
    service.invoke('stopService');
    if (stopCompleter != null) {
      await stopCompleter!.future;
    } else {
      await Future.delayed(const Duration(seconds: 3));
    }
  }

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

  await service.startService();
  await service.isRunning();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (_isLocationListening) return;
  _isLocationListening = true;

  if (service is AndroidServiceInstance) {
    stopCompleter = Completer<void>();
    service.setForegroundNotificationInfo(
      title: "Location Tracking",
      content: "Tracking your location in background",
    );
    service.on('stopService').listen((event) async {
      await _positionStream?.cancel();
      _isLocationListening = false;
      _isServiceStarted = false;
      _positionStream = null;
      stopCompleter?.complete();
      stopCompleter = null;
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

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
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
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor:
                          darkMode ? Color(0xFF1C1C1E) : Colors.white,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.06,
                          vertical: height * 0.035,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: width * 0.15,
                              color:
                                  darkMode
                                      ? Color(0xFF34A8EB)
                                      : Color(0xFF0169AA),
                            ),
                            SizedBox(height: height * 0.02),
                            Text(
                              "Enable Background Location",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cabin(
                                fontSize: width * 0.05,
                                fontWeight: FontWeight.bold,
                                color: darkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: height * 0.015),
                            Text(
                              "This app needs location access all the time to accurately track your activity even when the app is closed.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cabin(
                                fontSize: width * 0.04,
                                color:
                                    darkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: height * 0.03),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(
                                    "Not Now",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          darkMode
                                              ? Colors.white70
                                              : Colors.black54,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        darkMode
                                            ? Color(0xFF34A8EB)
                                            : Color(0xFF0169AA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.08,
                                      vertical: height * 0.015,
                                    ),
                                  ),
                                  child: Text(
                                    "Open Settings",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.04,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
            (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: darkMode ? Color(0xFF1C1C1E) : Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.06,
                  vertical: height * 0.035,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: width * 0.15,
                      color: darkMode ? Color(0xFF34A8EB) : Color(0xFF0169AA),
                    ),
                    SizedBox(height: height * 0.02),
                    Text(
                      "Location Permission Needed",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cabin(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: darkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: height * 0.015),
                    Text(
                      "To function properly, this app needs location access. Please enable location permission in your app settings.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cabin(
                        fontSize: width * 0.04,
                        color: darkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                darkMode
                                    ? Color(0xFF34A8EB)
                                    : Color(0xFF0169AA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.08,
                              vertical: height * 0.015,
                            ),
                          ),
                          child: Text(
                            "OK",
                            style: GoogleFonts.cabin(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.04,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      );
      openAppSettings();
    }
  }
}
