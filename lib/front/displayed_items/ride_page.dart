import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/map_and_location/get_functions.dart';
import 'package:driver_app/front/tools/consts.dart';
import 'package:driver_app/front/tools/get_location_name.dart';
import 'package:driver_app/front/tools/ride_model.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:timeline_tile/timeline_tile.dart';

class RidePage extends StatefulWidget {
  const RidePage({super.key});

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  StreamSubscription<QuerySnapshot>? carsSubscription;
  Map<String, dynamic>? userData;
  List<Ride> filteredRides = [];
  List<Map<String, dynamic>> currentRides = [];
  Map<String, dynamic>? nextRoute;
  ValueNotifier<bool> isAnimatingCamera = ValueNotifier<bool>(false);
  String? docId;
  String? routeKey;

  String? startLocationName;
  String? endLocationName;

  LocationData? startLatLngObj;
  LatLng? currentLocation;
  LatLng? endLatLngObj;
  double? speedMps;

  final PanelController _panelController = PanelController();
  bool isStarted = false;
  bool isUserInteracting = false;
  bool? swipeButtonEnable;
  bool toComplete = false;

  bool? startArrived;
  bool? endArrived;

  GoogleMapController? mapController;
  Map<PolylineId, Polyline> polylines = {};
  CameraPosition? initialCameraPosition;
  late String _mapStyleDarkString;
  late String _mapStyleLightString;
  Location locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;
  Set<Marker> markers = {};

  void customMarker() {
    BitmapDescriptor.asset(
      ImageConfiguration(size: Size(50, 40)),
      'assets/Car.png',
    ).then((icon) {
      setState(() {
        customIcon = icon;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    customMarker();
    DefaultAssetBundle.of(
      context,
    ).loadString('assets/map_style_dark.json').then((value) {
      setState(() {
        _mapStyleDarkString = value;
      });
    });
    DefaultAssetBundle.of(
      context,
    ).loadString('assets/map_style_light.json').then((value) {
      setState(() {
        _mapStyleLightString = value;
      });
    });
    fetchUserData();
    getLocationUpdates(
      locationController: locationController,
      onLocationUpdate: (position) {
        if (mounted) {
          setState(() {
            startLatLngObj = position;
            currentLocation = LatLng(
              startLatLngObj!.latitude!,
              startLatLngObj!.longitude!,
            );
          });
        }

        if (currentLocation != null) {
          var start = MarkerId('start_location');
          var end = MarkerId('end_location');
          var newPosition = LatLng(
            currentLocation!.latitude,
            currentLocation!.longitude,
          );

          double distanceInMeters = Geolocator.distanceBetween(
            currentLocation!.latitude,
            currentLocation!.longitude,
            endLatLngObj!.latitude,
            endLatLngObj!.longitude,
          );

          swipeButtonEnable = distanceInMeters < 100;

          markers = {
            Marker(
              markerId: start,
              position: newPosition,
              icon: customIcon,
              anchor: const Offset(0.5, 0.5),
            ),
            Marker(
              markerId: end,
              position: endLatLngObj!,
              icon:
                  nextRoute!['Start Arrived']
                      ? BitmapDescriptor.defaultMarker
                      : BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
            ),
          };

          if (startLatLngObj != null && endLatLngObj != null) {
            getPolyLinePoints(
              googleApiKey: GOOGLE_MAPS_API_KEY,
              source: currentLocation!,
              destination: endLatLngObj!,
            ).then((coordinates) {
              if (coordinates.isNotEmpty) {
                final polylineId = PolylineId('main_route');
                final Polyline polyline = Polyline(
                  polylineId: polylineId,
                  color: Colors.blue,
                  width: 5,
                  points: coordinates,
                );

                if (mounted) {
                  setState(() {
                    polylines[polylineId] = polyline;
                  });
                }

                cameraToPosition(
                  mapController: _mapController,
                  position: newPosition,
                  currentPosition: startLatLngObj!,
                  isStarted: isStarted,
                  mid: getMidpoint(currentLocation, endLatLngObj),
                  zoom: getZoomLevel(distanceInMeters),
                  isUserInteracting: isUserInteracting,
                  isAnimatingCamera: isAnimatingCamera,
                );
              } else {
                logger.e('Failed to fetch polyline coordinates');
              }
            });
          }
        }
      },
    );
  }

  LatLng getMidpoint(LatLng? start, LatLng? end) {
    if (start == null || end == null) {
      return const LatLng(0.0, 0.0);
    }
    double midLat = (start.latitude + end.latitude) / 2;
    double midLng = (start.longitude + end.longitude) / 2;

    return LatLng(midLat, midLng);
  }

  Future<void> fetchUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .get();
        if (docSnapshot.exists) {
          setState(() {
            userData = docSnapshot.data();
          });
          fetchAndFilterRides(userData: userData!);
        }
      }
    } catch (e) {
      logger.e('Error fetching user\'s data: $e');
    }
  }

  Future<void> fetchAndFilterRides({
    required Map<String, dynamic> userData,
  }) async {
    carsSubscription = FirebaseFirestore.instance
        .collection('Cars')
        .snapshots()
        .listen((querySnapshot) {
          final allRides =
              querySnapshot.docs.map((doc) {
                return Ride.fromFirestore(data: doc.data(), id: doc.id);
              }).toList();
          final userId = FirebaseAuth.instance.currentUser?.uid;
          final filtered =
              allRides.where((ride) {
                return ride.driver == userId;
              }).toList();

          setState(() {
            filteredRides = filtered;
          });
          getCurrentDateRides();
        });
  }

  void getCurrentDateRides() {
    final List<Map<String, dynamic>> updatedRides = [];
    for (int i = 0; i < filteredRides.length; i++) {
      filteredRides[i].routes.forEach((key, route) {
        final Timestamp fetchedStartDate = route['StartDate'];
        final tourStartDate = fetchedStartDate.toDate();
        final startDate = DateTime(
          tourStartDate.year,
          tourStartDate.month,
          tourStartDate.day,
        );
        final currentDateTime = DateTime(2025, 01, 13);
        final currentDate = DateTime(
          currentDateTime.year,
          currentDateTime.month,
          currentDateTime.day,
        );

        if (startDate.isAtSameMomentAs(currentDate)) {
          updatedRides.add(route);
        }
      });
      setState(() {
        currentRides = updatedRides;
        updateNextRoute();
      });
    }
  }

  void updateNextRoute() async {
    if (currentRides.isEmpty) {
      setState(() {
        nextRoute = null;
      });
      return;
    }

    nextRoute = currentRides.firstWhere((routeData) {
      return !(routeData["Start Arrived"] as bool) ||
          !(routeData["End Arrived"] as bool);
    }, orElse: () => {});

    if (nextRoute != null) {
      int routeIndex = currentRides.indexOf(nextRoute!);
      routeKey = "Route${routeIndex + 1}";
      docId = nextRoute!['ID'];

      String endCoordinates =
          nextRoute!['Start Arrived'] == false
              ? nextRoute!['Start']
              : nextRoute!['End'];
      List<String> endLatLng = endCoordinates.split(",");
      double endLat = double.parse(endLatLng[0]);
      double endLng = double.parse(endLatLng[1]);
      String startLocation = nextRoute!['Start'];
      List<String> startLatLng = startLocation.split(",");
      double startLat = double.parse(startLatLng[0]);
      double startLng = double.parse(startLatLng[1]);

      String startLocationDraft = await getLocationName(startLat, startLng);
      String endLocation = nextRoute!['End'];
      List<String> endLocationLatLng = endLocation.split(",");
      double endLocationLat = double.parse(endLocationLatLng[0]);
      double endLocationLng = double.parse(endLocationLatLng[1]);
      String endLocationDraft = await getLocationName(
        endLocationLat,
        endLocationLng,
      );
      startArrived = nextRoute!['Start Arrived'];
      endArrived = nextRoute!['End Arrived'];

      if (mounted) {
        setState(() {
          endLatLngObj = LatLng(endLat, endLng);
          startLocationName = startLocationDraft;
          endLocationName = endLocationDraft;
        });
      }
    }
  }

  double getZoomLevel(double distanceInMeters) {
    double zoomLevel = 15.0;

    if (distanceInMeters < 500) {
      zoomLevel = 16.0;
    } else if (distanceInMeters < 1000) {
      zoomLevel = 12.0;
    } else if (distanceInMeters < 5000) {
      zoomLevel = 10.0;
    } else {
      zoomLevel = 8.0;
    }

    return zoomLevel;
  }

  Future<void> _moveCameraToCurrentLocation() async {
    if (_mapController.isCompleted) {
      setState(() {
        isUserInteracting = false;
      });
    }
  }

  @override
  void dispose() {
    carsSubscription?.cancel();
    if (mapController != null) {
      mapController!.dispose();
    }
    if (_mapController.isCompleted) {
      _mapController.future.then((controller) {
        controller.dispose();
      });
    }
    isAnimatingCamera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (startLatLngObj == null) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child:
            nextRoute != null
                ? Stack(
                  children: [
                    SizedBox(
                      child: GoogleMap(
                        onCameraMoveStarted: () {
                          setState(() {
                            isUserInteracting = true;
                          });
                        },
                        onMapCreated: (controller) {
                          if (!_mapController.isCompleted) {
                            _mapController.complete(controller);
                          }
                        },
                        initialCameraPosition:
                            initialCameraPosition ??
                            CameraPosition(
                              target: currentLocation ?? const LatLng(0, 0),
                              zoom: 15,
                            ),
                        zoomControlsEnabled: false,

                        mapType: MapType.normal,
                        style:
                            darkMode
                                ? _mapStyleDarkString
                                : _mapStyleLightString,
                        compassEnabled: false,
                        tiltGesturesEnabled: true,
                        markers: markers,
                        polylines: Set<Polyline>.of(polylines.values),
                      ),
                    ),
                    Positioned(
                      top: height * 0.017,
                      child: IconButton(
                        onPressed: () {
                          navigatorKey.currentState?.pop();
                        },
                        icon: Icon(
                          Icons.arrow_circle_left_rounded,
                          size: width * 0.1,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: height * 0.12,
                      right: width * 0.02,
                      child: GestureDetector(
                        onTap: () {
                          if (currentLocation != null) {
                            _moveCameraToCurrentLocation();
                          }
                        },
                        child: Container(
                          width: width * 0.1,
                          height: width * 0.1,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 3,
                                blurStyle: BlurStyle.outer,
                                color: Colors.grey.shade200,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.my_location,
                            size: width * 0.055,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SlidingUpPanel(
                      maxHeight: height * 0.42,
                      minHeight: height * 0.08,
                      parallaxEnabled: true,
                      parallaxOffset: .5,
                      borderRadius: BorderRadius.circular(width * 0.05),
                      padding: EdgeInsets.all(width * 0.019),
                      controller: _panelController,
                      backdropTapClosesPanel: true,
                      panel: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          SizedBox(height: height * 0.004),
                          Container(
                            width: width * 0.2,
                            height: height * 0.007,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(width * 0.05),
                              color: Colors.grey.shade400,
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          TextButton(
                            onPressed: () {
                              _panelController.isPanelOpen
                                  ? _panelController.close()
                                  : _panelController.open();
                            },
                            child: Text(
                              "Ride Details",
                              style: GoogleFonts.notoSans(
                                fontSize: width * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Positioned(
                            top: height * 0.004,
                            child: SizedBox(
                              width: width * 0.95,
                              height: height * 0.38,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TimelineTile(
                                    alignment: TimelineAlign.start,
                                    indicatorStyle: IndicatorStyle(
                                      color: Colors.black,
                                      drawGap: true,
                                      width: width * 0.076,
                                      height: height * 0.03,
                                      indicator: Transform.rotate(
                                        angle: pi,
                                        child: Image.asset('assets/Car.png'),
                                      ),
                                    ),
                                    isFirst: true,
                                    hasIndicator: true,
                                    afterLineStyle: LineStyle(
                                      color:
                                          startArrived!
                                              ? Colors.green.shade600
                                              : Colors.black,
                                      thickness: width * 0.0076,
                                    ),
                                  ),
                                  TimelineTile(
                                    alignment: TimelineAlign.start,
                                    indicatorStyle: IndicatorStyle(
                                      color: Colors.black,
                                      drawGap: true,
                                      width: width * 0.076,
                                      height: height * 0.05,
                                      indicator: Image.asset(
                                        'assets/location.png',
                                        color:
                                            startArrived!
                                                ? Colors.green.shade600
                                                : Colors.blue.shade800,
                                      ),
                                    ),

                                    hasIndicator: true,
                                    beforeLineStyle: LineStyle(
                                      color:
                                          startArrived!
                                              ? Colors.green.shade600
                                              : Colors.black,

                                      thickness: width * 0.0076,
                                    ),
                                    afterLineStyle: LineStyle(
                                      color:
                                          startArrived!
                                              ? endArrived!
                                                  ? Colors.green.shade600
                                                  : Colors.black
                                              : Colors.grey.shade300,

                                      thickness: width * 0.0076,
                                    ),
                                    lineXY: 1,

                                    endChild: SizedBox(
                                      height: height * 0.08,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          startLocationName ?? '',
                                          style: GoogleFonts.notoSans(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: width * 0.04,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TimelineTile(
                                    alignment: TimelineAlign.start,
                                    indicatorStyle: IndicatorStyle(
                                      color: Colors.black,
                                      drawGap: true,
                                      width: width * 0.076,
                                      height: height * 0.03,
                                      indicator: Image.asset(
                                        'assets/location.png',
                                        color:
                                            startArrived!
                                                ? Colors.red.shade800
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    isLast: true,
                                    hasIndicator: true,
                                    beforeLineStyle: LineStyle(
                                      color:
                                          startArrived!
                                              ? endArrived!
                                                  ? Colors.green.shade600
                                                  : Colors.black
                                              : Colors.grey.shade300,

                                      thickness: width * 0.0076,
                                    ),

                                    endChild: SizedBox(
                                      height: height * 0.08,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          endLocationName ?? '',
                                          style: GoogleFonts.notoSans(
                                            color:
                                                startArrived!
                                                    ? Colors.black
                                                    : Colors.grey.shade300,
                                            fontWeight: FontWeight.w600,
                                            fontSize: width * 0.04,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: height * 0.3,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  width * 0.019,
                                ),
                                boxShadow:
                                    isStarted
                                        ? swipeButtonEnable!
                                            ? [
                                              BoxShadow(
                                                blurRadius: 5,
                                                blurStyle: BlurStyle.outer,
                                                color: Colors.black45,
                                                spreadRadius: 0.4,
                                              ),
                                            ]
                                            : []
                                        : [
                                          BoxShadow(
                                            blurRadius: 5,
                                            blurStyle: BlurStyle.outer,
                                            color: Colors.black45,
                                            spreadRadius: 0.4,
                                          ),
                                        ],
                              ),
                              child: SwipeButton(
                                thumb: Padding(
                                  padding: EdgeInsets.all(width * 0.02),

                                  child: Image.asset(
                                    'assets/start_icon.png',
                                    color:
                                        isStarted
                                            ? swipeButtonEnable!
                                                ? Colors.black
                                                : Colors.white
                                            : Colors.black,
                                  ),
                                ),

                                width: width * 0.95,
                                borderRadius: BorderRadius.circular(
                                  width * 0.019,
                                ),
                                activeThumbColor: Colors.white,
                                inactiveTrackColor: Colors.white,
                                activeTrackColor: Colors.black38,
                                inactiveThumbColor: Colors.white,
                                enabled: isStarted ? swipeButtonEnable! : true,
                                onSwipe:
                                    isStarted
                                        ? startArrived!
                                            ? () async {
                                              setState(() {
                                                isStarted = !isStarted;
                                                isUserInteracting = false;
                                                toComplete = !toComplete;
                                              });
                                              await FirebaseFirestore.instance
                                                  .collection('Cars')
                                                  .doc(docId)
                                                  .set({
                                                    'Routes': {
                                                      routeKey!: {
                                                        'End Arrived': true,
                                                      },
                                                    },
                                                  }, SetOptions(merge: true));
                                              _panelController.close();
                                              navigatorKey.currentState?.pop();
                                            }
                                            : () async {
                                              setState(() {
                                                isStarted = !isStarted;
                                                isUserInteracting = false;
                                                toComplete = !toComplete;
                                              });
                                              await FirebaseFirestore.instance
                                                  .collection('Cars')
                                                  .doc(docId)
                                                  .set({
                                                    'Routes': {
                                                      routeKey!: {
                                                        'Start Arrived': true,
                                                      },
                                                    },
                                                  }, SetOptions(merge: true));
                                              _panelController.close();
                                            }
                                        : () {
                                          setState(() {
                                            isStarted = !isStarted;
                                            isUserInteracting = false;
                                            toComplete = !toComplete;
                                          });
                                          _panelController.close();
                                        },
                                child: Text(
                                  toComplete
                                      ? 'Complete the ride'
                                      : 'Start the ride',
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: width * 0.045,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                : const Text('No routes available for Today'),
      ),
    );
  }
}
