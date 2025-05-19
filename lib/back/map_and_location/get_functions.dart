import 'dart:async';
import 'dart:math';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/map_and_location/location_post_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:shared_preferences/shared_preferences.dart';

LatLng? lastLatLng;

bool hasMovedSignificantly(double lat, double lng, double thresholdMeters) {
  if (lastLatLng == null) return true;

  final double earthRadius = 6371000; 
  final double dLat = _degreesToRadians(lat - lastLatLng!.latitude);
  final double dLng = _degreesToRadians(lng - lastLatLng!.longitude);

  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lastLatLng!.latitude)) *
          cos(_degreesToRadians(lat)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final double c = 2 * asin(sqrt(a));
  final double distance = earthRadius * c;

  return distance > thresholdMeters;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

@pragma('vm:entry-point')
void headlessTask(bg.HeadlessEvent headlessEvent) async {
  logger.d('[BackgroundGeolocation HeadlessTask]: $headlessEvent');
  switch (headlessEvent.name) {
    case bg.Event.TERMINATE:
      bg.State state = headlessEvent.event;
      logger.d('- State: $state');
      break;
    case bg.Event.HEARTBEAT:
      final prefs = await SharedPreferences.getInstance();
      final docId = prefs.getString('docId');
      final startDateStr = prefs.getString('startDate');
      final endDateStr = prefs.getString('endDate');
      final endArrived = prefs.getBool('endArrived') ?? true;

      if (docId != null && startDateStr != null && endDateStr != null) {
        final now = DateTime.now();
        final startDate = DateTime.tryParse(
          startDateStr,
        )?.subtract(Duration(hours: 2));
        final endDate = DateTime.tryParse(endDateStr)?.add(Duration(hours: 5));

        if (startDate != null &&
            endDate != null &&
            now.isAfter(startDate) &&
            now.isBefore(endDate) &&
            !endArrived) {
          final bg.Location location = headlessEvent.event;
          await sendLocationToBackend(
            docId: docId,
            latitude: location.coords.latitude,
            longitude: location.coords.longitude,
            speedKph: location.coords.speed * 3.6,
          );
        } else {
          logger.d(
            '[headlessTask] Skipped location — outside time bounds or already arrived',
          );
        }
      } else {
        logger.w(
          '[headlessTask] Missing shared prefs data — skipping location post',
        );
      }
      break;
    case bg.Event.LOCATION:
      final prefs = await SharedPreferences.getInstance();
      final docId = prefs.getString('docId');
      final startDateStr = prefs.getString('startDate');
      final endDateStr = prefs.getString('endDate');
      final endArrived = prefs.getBool('endArrived') ?? true;

      if (docId != null && startDateStr != null && endDateStr != null) {
        final now = DateTime.now();
        final startDate = DateTime.tryParse(
          startDateStr,
        )?.subtract(Duration(hours: 2));
        final endDate = DateTime.tryParse(endDateStr)?.add(Duration(hours: 5));

        if (startDate != null &&
            endDate != null &&
            now.isAfter(startDate) &&
            now.isBefore(endDate) &&
            !endArrived) {
          final bg.Location location = headlessEvent.event;
          await sendLocationToBackend(
            docId: docId,
            latitude: location.coords.latitude,
            longitude: location.coords.longitude,
            speedKph: location.coords.speed * 3.6,
          );
        } else {
          logger.d(
            '[headlessTask] Skipped location — outside time bounds or already arrived',
          );
        }
      } else {
        logger.w(
          '[headlessTask] Missing shared prefs data — skipping location post',
        );
      }
      break;
    case bg.Event.MOTIONCHANGE:
      bg.Location location = headlessEvent.event;
      logger.d('- Location: $location');
      break;
    case bg.Event.GEOFENCE:
      bg.GeofenceEvent geofenceEvent = headlessEvent.event;
      logger.d('- GeofenceEvent: $geofenceEvent');
      break;
    case bg.Event.GEOFENCESCHANGE:
      bg.GeofencesChangeEvent event = headlessEvent.event;
      logger.d('- GeofencesChangeEvent: $event');
      break;
    case bg.Event.SCHEDULE:
      bg.State state = headlessEvent.event;
      logger.d('- State: $state');
      break;
    case bg.Event.ACTIVITYCHANGE:
      bg.ActivityChangeEvent event = headlessEvent.event;
      logger.d('ActivityChangeEvent: $event');
      break;
    case bg.Event.HTTP:
      bg.HttpEvent response = headlessEvent.event;
      logger.d('HttpEvent: $response');
      break;
    case bg.Event.POWERSAVECHANGE:
      bool enabled = headlessEvent.event;
      logger.d('ProviderChangeEvent: $enabled');
      break;
    case bg.Event.CONNECTIVITYCHANGE:
      bg.ConnectivityChangeEvent event = headlessEvent.event;
      logger.d('ConnectivityChangeEvent: $event');
      break;
    case bg.Event.ENABLEDCHANGE:
      bool enabled = headlessEvent.event;
      logger.d('EnabledChangeEvent: $enabled');
      break;
  }
}

/// Initialize foreground geolocation
Future<void> initializeForegroundTracking({
  required BuildContext context,
  required void Function({
    required double latitude,
    required double longitude,
    required double speedKph,
    required double heading,
    required String timestamp,
  })
  onLocation,
}) async {
  await _startTrackingService(onLocation);
}

/// Initialize background geolocation
Future<void> initializeBackgroundTracking({
  required void Function({
    required double latitude,
    required double longitude,
    required double speedKph,
    required double heading,
    required String timestamp,
  })
  onLocation,
}) async {
  await _startTrackingService(onLocation);
}

Future<void> _startTrackingService(
  void Function({
    required double latitude,
    required double longitude,
    required double speedKph,
    required double heading,
    required String timestamp,
  })
  onLocation,
) async {
  await bg.BackgroundGeolocation.ready(
    bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_NAVIGATION,
      distanceFilter: 30,
      stopOnTerminate: false,
      heartbeatInterval: 60,
      startOnBoot: true,
      enableTimestampMeta: true,
      useSignificantChangesOnly: false,
      stopOnStationary: true,
      stationaryRadius: 25,
      preventSuspend: true,
      enableHeadless: true,
      foregroundService: true,
      forceReloadOnLocationChange: true,
      showsBackgroundLocationIndicator: true,
      notification: bg.Notification(
        title: "Location Tracking",
        text: "Tracking your location in background",
      ),
      debug: false,
      logLevel: bg.Config.LOG_LEVEL_OFF,
    ),
  );

  final state = await bg.BackgroundGeolocation.state;
  if (!state.enabled) {
    await bg.BackgroundGeolocation.start();
  }

  bg.BackgroundGeolocation.onLocation((bg.Location location) {
    final coords = location.coords;
    onLocation(
      latitude: coords.latitude,
      longitude: coords.longitude,
      speedKph: coords.speed * 3.6,
      heading: coords.heading,
      timestamp: location.timestamp,
    );
  });

  bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
    logger.e(
      '[providerchange] enabled: ${event.enabled}, gps: ${event.gps}, network: ${event.network}',
    );

    if (!event.enabled) {
      logger.e('⚠️ Location services are disabled. Tracking will not work.');
    }
  });
}

Future<void> requestIgnoreBatteryOptimizations(BuildContext context) async {
  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  final isIgnoring = await bg.DeviceSettings.isIgnoringBatteryOptimizations;
  if (isIgnoring || !context.mounted) return;

  final confirm =
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return Dialog(
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
                    Icons.battery_alert_rounded,
                    size: width * 0.15,
                    color: darkMode ? Color(0xFF34A8EB) : Color(0xFF0169AA),
                  ),
                  SizedBox(height: height * 0.02),
                  Text(
                    "Disable Battery Optimization",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cabin(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: darkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: height * 0.015),
                  Text(
                    "To ensure accurate background tracking, please disable battery optimizations for this app in the next screen.\n\nTap the 3-dot menu → All apps → Find this app → Choose 'Don't optimize' or 'Unrestricted'.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cabin(
                      fontSize: width * 0.04,
                      color: darkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          "Later",
                          style: GoogleFonts.cabin(
                            fontWeight: FontWeight.w600,
                            color: darkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              darkMode ? Color(0xFF34A8EB) : Color(0xFF0169AA),
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
      false;

  if (confirm) {
    final request = await bg.DeviceSettings.showIgnoreBatteryOptimizations();

    if (request.seen) {
      logger.i(
        '[BatteryOptimizations] Screen already shown on ${request.lastSeenAt}',
      );
      return;
    }

    await bg.DeviceSettings.show(request);
  }
}

/// Request permissions with dialogs
Future<void> requestLocationPermissions(BuildContext context) async {
  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

  final PermissionStatus foregroundStatus =
      await Permission.locationWhenInUse.request();
  if (foregroundStatus.isGranted) {
    final PermissionStatus backgroundStatus =
        await Permission.locationAlways.status;
    if (backgroundStatus.isGranted) return;

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
  } else if (foregroundStatus.isPermanentlyDenied && context.mounted) {
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
                              darkMode ? Color(0xFF34A8EB) : Color(0xFF0169AA),
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

Future<void> sendLocationToBackend({
  required String docId,
  required double latitude,
  required double longitude,
  required double speedKph,
}) async {
  if (!hasMovedSignificantly(latitude, longitude, 25)) {
    logger.d('[headlessTask] ⏩ Skipped (no significant movement)');
    return;
  }

  try {
    lastLatLng = LatLng(latitude, longitude);
    await LocationPostApi().postData({
      "CarID": docId,
      "Lat": latitude.toString(),
      "Long": longitude.toString(),
      "Speed": speedKph,
    });
  } catch (e) {
    logger.e('[headlessTask] ❌ Failed to post location: $e');
  }
}
