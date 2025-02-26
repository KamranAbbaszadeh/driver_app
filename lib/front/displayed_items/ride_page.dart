import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/front/displayed_items/chat_page.dart';
import 'package:driver_app/front/tools/get_location_name.dart';
import 'package:driver_app/front/tools/ride_model.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_sliding_panel/flutter_sliding_panel.dart';
// import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class RidePage extends StatefulWidget {
  final LatLng? currentLocation;
  final double? currentSpeed;
  const RidePage({
    super.key,
    required this.currentLocation,
    required this.currentSpeed,
  });

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
  String tourName = '';

  String? startLocationName;
  String? endLocationName;

  LocationData? startLatLngObj;
  LatLng? endLatLng;
  LatLng? startLatLng;
  double? speedMps;

  final SlidingPanelController _panelController = SlidingPanelController();
  bool isStarted = false;
  bool isUserInteracting = false;
  bool? swipeButtonEnable;
  bool toComplete = false;

  bool? startArrived;
  bool? endArrived;

  Position? currentPosition;
  double currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  LatLng getMidpoint(LatLng? start, LatLng? end, LatLng? current) {
    if (start == null || end == null || current == null) {
      return const LatLng(0.0, 0.0);
    }
    double midLat = (start.latitude + end.latitude + current.latitude) / 3;
    double midLng = (start.longitude + end.longitude + current.longitude) / 3;

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
        final currentDateTime = DateTime(2025, 02, 16);
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

      String startLocation = nextRoute!['Start'];
      List<String> startLatLngString = startLocation.split(",");
      double startLat = double.parse(startLatLngString[0]);
      double startLng = double.parse(startLatLngString[1]);

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
          endLatLng = LatLng(endLocationLat, endLocationLng);
          startLatLng = LatLng(startLat, startLng);
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

  // Future<void> _moveCameraToCurrentLocation() async {
  //   if (_mapController.isCompleted) {
  //     setState(() {
  //       isUserInteracting = false;
  //     });
  //   }
  // }

  @override
  void dispose() {
    carsSubscription?.cancel();
    // if (mapController != null) {
    //   mapController!.dispose();
    // }
    // if (_mapController.isCompleted) {
    //   _mapController.future.then((controller) {
    //     controller.dispose();
    //   });
    // }
    isAnimatingCamera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    // final darkMode =
    //     MediaQuery.of(context).platformBrightness == Brightness.dark;
    final startArrivedBool = startArrived;

    if (startLatLngObj == null) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final midPoint = getMidpoint(
      startLatLng,
      endLatLng,
      widget.currentLocation,
    );
    final distance =
        endLatLng != null && widget.currentLocation != null
            ? Geolocator.distanceBetween(
              widget.currentLocation!.latitude,
              widget.currentLocation!.longitude,
              endLatLng!.latitude,
              endLatLng!.longitude,
            )
            : 0.0;
    setState(() {});
    final zoomLvl = getZoomLevel(distance);

    return Scaffold(
      body: Center(
        child:
            nextRoute != null
                ? Stack(
                  children: [
                    SizedBox(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            midPoint.latitude,
                            midPoint.longitude,
                          ),
                          initialZoom: zoomLvl,
                        ),
                        children: [
                          TileLayer(
                            // Display map tiles from any source
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                            userAgentPackageName: 'com.example.app',
                            // And many more recommended properties!
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: widget.currentLocation!,
                                child: Image.asset(
                                  'assets/Car.png',
                                  width: width * 0.1,
                                  height: height * 0.1,
                                ),
                              ),
                              Marker(
                                point: startLatLng ?? LatLng(0.0, 0.0),
                                width: width * 0.1,
                                height: height * 0.065,
                                child: Column(
                                  children: [
                                    Container(
                                      width: width * 0.08,
                                      height: height * 0.035,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white),
                                        color: Colors.black,
                                      ),

                                      child: Center(
                                        child: Text(
                                          '1',
                                          style: GoogleFonts.cabin(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: width * 0.03,
                                      height: height * 0.03,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white),
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Marker(
                                point: endLatLng ?? LatLng(0.0, 0.0),
                                width: width * 0.1,
                                height: height * 0.065,
                                child: Column(
                                  children: [
                                    Container(
                                      width: width * 0.08,
                                      height: height * 0.035,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white),
                                        color: Colors.black,
                                      ),

                                      child: Center(
                                        child: Text(
                                          '2',
                                          style: GoogleFonts.cabin(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: width * 0.03,
                                      height: height * 0.03,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white),
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
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
                      child: Text(
                        widget.currentSpeed.toString(),
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                    SlidingPanel(
                      controller: _panelController,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 5,
                            spreadRadius: 2,
                            color: Color(0x11000000),
                          ),
                        ],
                      ),
                      config: SlidingPanelConfig(
                        anchorPosition: height * 0.10,
                        expandPosition: height * 0.43,
                      ),
                      panelContent: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: height * 0.004),

                          Row(
                            children: [
                              SizedBox(width: width * 0.33),
                              Text(
                                "Ride Details",
                                style: GoogleFonts.notoSans(
                                  fontSize: width * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 80),
                              FloatingActionButton(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  255,
                                ),
                                splashColor: Colors.transparent,

                                mini: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child:
                                    ValueListenableBuilder<SlidingPanelDetail>(
                                      valueListenable: _panelController,
                                      builder: (_, detail, __) {
                                        return Icon(
                                          detail.status ==
                                                  SlidingPanelStatus.anchored
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                  .keyboard_arrow_down_rounded,
                                        );
                                      },
                                    ),
                                onPressed: () {
                                  if (_panelController.status ==
                                      SlidingPanelStatus.anchored) {
                                    _panelController.expand();
                                  } else {
                                    _panelController.anchor();
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          SizedBox(
                            width: width * 0.95,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: 20,
                                  children: [
                                    Container(
                                      width: width * 0.1,
                                      height: height * 0.05,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white),
                                        color:
                                            startArrivedBool != null
                                                ? startArrivedBool
                                                    ? const Color.fromARGB(
                                                      255,
                                                      103,
                                                      168,
                                                      120,
                                                    )
                                                    : Colors.black
                                                : Colors.black,
                                      ),

                                      child: Center(
                                        child: Text(
                                          '1',
                                          style: GoogleFonts.cabin(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: width * 0.8,
                                      child: Text(
                                        startLocationName ?? "",
                                        softWrap: true,
                                        style: GoogleFonts.cabin(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.01),
                                Row(
                                  spacing: 20,
                                  children: [
                                    Container(
                                      width: width * 0.1,
                                      height: height * 0.05,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white),
                                        color: Colors.black,
                                      ),

                                      child: Center(
                                        child: Text(
                                          '2',
                                          style: GoogleFonts.cabin(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: width * 0.8,
                                      child: Text(
                                        endLocationName ?? "",
                                        softWrap: true,
                                        style: GoogleFonts.cabin(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Divider(
                            color: const Color.fromARGB(180, 183, 182, 182),
                            thickness: 2,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 10,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    width * 0.019,
                                  ),
                                  color: const Color.fromARGB(
                                    180,
                                    183,
                                    182,
                                    182,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ChatPage(
                                                  tourId: docId!,
                                                  width: width,
                                                  height: height,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.message,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Positioned(
                                      top: 23.5,
                                      left: 44,
                                      height: 13,
                                      width: 13,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    width * 0.019,
                                  ),
                                  color: const Color.fromARGB(
                                    180,
                                    183,
                                    182,
                                    182,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ChatPage(
                                              tourId: docId!,
                                              width: width,
                                              height: height,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: Transform.rotate(
                                    angle: 90 * (pi / 180),
                                    child: Icon(
                                      Icons.navigation_sharp,
                                      color: Colors.black,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          //
                          // SwipeButton(
                          //   thumb: Padding(
                          //     padding: EdgeInsets.all(width * 0.02),

                          //     child: Image.asset(
                          //       'assets/start_icon.png',
                          //       color:
                          //           isStarted
                          //               ? swipeButtonEnable!
                          //                   ? Colors.black
                          //                   : Colors.white
                          //               : Colors.black,
                          //     ),
                          //   ),

                          //   width: width * 0.95,
                          //   borderRadius: BorderRadius.circular(
                          //     width * 0.019,
                          //   ),
                          //   activeThumbColor: Colors.white,
                          //   inactiveTrackColor: Colors.white,
                          //   activeTrackColor: Colors.black38,
                          //   inactiveThumbColor: Colors.white,
                          //   enabled: isStarted ? swipeButtonEnable! : true,
                          //   onSwipe:
                          //       isStarted
                          //           ? startArrived!
                          //               ? () async {
                          //                 setState(() {
                          //                   isStarted = !isStarted;
                          //                   isUserInteracting = false;
                          //                   toComplete = !toComplete;
                          //                 });
                          //                 await FirebaseFirestore.instance
                          //                     .collection('Cars')
                          //                     .doc(docId)
                          //                     .set({
                          //                       'Routes': {
                          //                         routeKey!: {
                          //                           'End Arrived': true,
                          //                         },
                          //                       },
                          //                     }, SetOptions(merge: true));
                          //                 _panelController.close();
                          //                 navigatorKey.currentState?.pop();
                          //               }
                          //               : () async {
                          //                 setState(() {
                          //                   isStarted = !isStarted;
                          //                   isUserInteracting = false;
                          //                   toComplete = !toComplete;
                          //                 });
                          //                 await FirebaseFirestore.instance
                          //                     .collection('Cars')
                          //                     .doc(docId)
                          //                     .set({
                          //                       'Routes': {
                          //                         routeKey!: {
                          //                           'Start Arrived': true,
                          //                         },
                          //                       },
                          //                     }, SetOptions(merge: true));
                          //                 _panelController.close();
                          //               }
                          //           : () {
                          //             setState(() {
                          //               isStarted = !isStarted;
                          //               isUserInteracting = false;
                          //               toComplete = !toComplete;
                          //             });
                          //             _panelController.close();
                          //           },
                          //   child: Text(
                          //     toComplete
                          //         ? 'Complete the ride'
                          //         : 'Start the ride',
                          //     style: GoogleFonts.notoSans(
                          //       color: Colors.white54,
                          //       fontWeight: FontWeight.w600,
                          //       fontSize: width * 0.045,
                          //     ),
                          //   ),
                          // ),
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
