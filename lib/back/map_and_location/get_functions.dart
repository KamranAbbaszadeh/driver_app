import 'dart:async';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

@pragma('vm:entry-point')
void headlessTask(bg.HeadlessEvent headlessEvent) async {
  logger.d('[BackgroundGeolocation HeadlessTask]: $headlessEvent');
  // Implement a 'case' for only those events you're interested in.
  switch (headlessEvent.name) {
    case bg.Event.TERMINATE:
      bg.State state = headlessEvent.event;
      logger.d('- State: $state');
      break;
    case bg.Event.HEARTBEAT:
      bg.HeartbeatEvent event = headlessEvent.event;
      logger.d('- HeartbeatEvent: $event');
      break;
    case bg.Event.LOCATION:
      bg.Location location = headlessEvent.event;
      logger.d('- Location: $location');
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
  await requestLocationPermissions(context);
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
      distanceFilter: 10,
      stopOnTerminate: false,
      startOnBoot: true,
      enableTimestampMeta: true,
      useSignificantChangesOnly: false,
      stopOnStationary: true,
      stationaryRadius: 1,
      preventSuspend: false,
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
