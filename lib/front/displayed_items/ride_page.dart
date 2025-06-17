import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/map_and_location/get_functions.dart';
import 'package:onemoretour/back/map_and_location/location_provider.dart';
import 'package:onemoretour/back/map_and_location/ride_flow_provider.dart';
import 'package:onemoretour/back/ride/guest_pick_up_api.dart';
import 'package:onemoretour/front/displayed_items/chat_page.dart';
import 'package:onemoretour/front/displayed_items/intermediate_page.dart';
import 'package:onemoretour/front/displayed_items/ride_map.dart';
import 'package:onemoretour/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sliding_panel/flutter_sliding_panel.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onemoretour/back/ride/ride_state.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RidePage extends ConsumerStatefulWidget {
  const RidePage({super.key});

  @override
  ConsumerState<RidePage> createState() => _RidePageState();
}

class _RidePageState extends ConsumerState<RidePage>
    with TickerProviderStateMixin {
  final SlidingPanelController _panelController = SlidingPanelController();
  StreamSubscription? _locationSubscription;

  bool isFinished = false;
  bool hasUnreadChat = false;
  bool _isMounted = false;
  bool guestPickedUp = false;
  double? targetRadius;
  @override
  void initState() {
    super.initState();
    _isMounted = true;

    _checkUnreadMessages();
    getTargetRadius().then((value) {
      if (mounted) {
        setState(() {
          targetRadius = value;
        });
      }
    });
    initializeForegroundTracking(
      context: context,
      onLocation: ({
        required double latitude,
        required double longitude,
        required double speedKph,
        required double heading,
        required String timestamp,
      }) {
        if (!_isMounted) return;

        ref.read(locationProvider.notifier).state = {
          'latitude': latitude,
          'longitude': longitude,
          'speed': speedKph,
          'heading': heading,
          'timestamp': timestamp,
        };
      },
    );
  }

  LatLng getMidpoint(LatLng? start, LatLng? end, LatLng? current) {
    if (start == null || end == null || current == null) {
      return const LatLng(0.0, 0.0);
    }
    double midLat = (start.latitude + end.latitude + current.latitude) / 3;
    double midLng = (start.longitude + end.longitude + current.longitude) / 3;

    return LatLng(midLat, midLng);
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

  void _checkUnreadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesString = prefs.getString('notification_messages');
    if (messagesString != null) {
      final messages = jsonDecode(messagesString);
      final hasUnread = messages.any((notif) {
        final message = notif['message'] as Map<String, dynamic>?;
        final data = message?['data'] as Map<String, dynamic>?;
        return data?['route'] == '/chat_page' &&
            data?['tourId'] == ref.read(rideProvider).docId &&
            notif['isViewed'] == false;
      });

      setState(() {
        hasUnreadChat = hasUnread;
      });
    }
  }

  Future<double> getTargetRadius() async {
    DocumentSnapshot targetRadiusDoc =
        await FirebaseFirestore.instance
            .collection('Details')
            .doc('Ride')
            .get();
    return targetRadiusDoc['distance']?.toDouble() ?? 100.0;
  }

  @override
  void dispose() {
    _isMounted = false;
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final startLatLng = rideState.startLatLng;
    final endLatLng = rideState.endLatLng;
    final nextRoute = rideState.nextRoute;
    final docId = rideState.docId;
    final startLocationName = rideState.startLocationName;
    final endLocationName = rideState.endLocationName;
    final position = ref.watch(locationProvider);
    if (startLatLng == null || endLatLng == null || position == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (targetRadius == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final currentLocation = LatLng(position['latitude'], position['longitude']);

    final rideFlow = ref.watch(rideFlowProvider);
    final startArrivedBool = rideState.startArrived;
    final endArrivedBool = rideState.endArrived;
    final routeKey = rideState.routeKey;

    if (startArrivedBool == null || endArrivedBool == null) {
      return CircularProgressIndicator();
    }

    final rideFlowNotifier = ref.read(rideFlowProvider.notifier);

    final swipeButtonText =
        rideFlow.startRide
            ? startArrivedBool
                ? rideFlow.pickGuest
                    ? "Complete the ride"
                    : "Continue the ride"
                : "In place"
            : "Start the ride";
    final double distanceToTarget = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      (rideFlow.startRide && startArrivedBool == true)
          ? endLatLng.latitude
          : startLatLng.latitude,
      (rideFlow.startRide && startArrivedBool == true)
          ? endLatLng.longitude
          : startLatLng.longitude,
    );

    final bool isWithinRange = distanceToTarget <= targetRadius!;
    final navigateLat =
        rideFlow.startRide && startArrivedBool == true
            ? endLatLng.latitude
            : startLatLng.latitude;
    final navigateLong =
        rideFlow.startRide && startArrivedBool == true
            ? endLatLng.longitude
            : startLatLng.longitude;

    return Scaffold(
      body: Center(
        child:
            nextRoute != null
                ? Stack(
                  children: [
                    SizedBox(child: RideMap()),

                    Positioned(
                      top: height * 0.057,
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
                    SlidingPanel(
                      controller: _panelController,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(width * 0.05),
                          topRight: Radius.circular(width * 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: width * 0.012,
                            spreadRadius: width * 0.005,
                            color: Color(0x11000000),
                          ),
                        ],
                      ),
                      config: SlidingPanelConfig(
                        anchorPosition: height * 0.07,
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
                              SizedBox(width: width * 0.203),
                              FloatingActionButton(
                                heroTag: 'panel_toggle_btn',
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  255,
                                ),
                                splashColor: Colors.transparent,

                                mini: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    width * 0.05,
                                  ),
                                ),
                                child:
                                    ValueListenableBuilder<SlidingPanelDetail>(
                                      valueListenable: _panelController,
                                      builder: (_, detail, _) {
                                        return Icon(
                                          detail.status ==
                                                  SlidingPanelStatus.anchored
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                  .keyboard_arrow_down_rounded,
                                          color: Colors.black,
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
                                  spacing: width * 0.05,
                                  children: [
                                    Container(
                                      width: width * 0.1,
                                      height: height * 0.05,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          width * 0.02,
                                        ),
                                        border: Border.all(color: Colors.white),
                                        color:
                                            startArrivedBool
                                                ? const Color.fromARGB(
                                                  255,
                                                  103,
                                                  168,
                                                  120,
                                                )
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
                                  spacing: width * 0.05,
                                  children: [
                                    Container(
                                      width: width * 0.1,
                                      height: height * 0.05,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          width * 0.02,
                                        ),
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
                          SizedBox(height: height * 0.011),
                          Divider(
                            color: const Color.fromARGB(180, 183, 182, 182),
                            thickness: width * 0.005,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: width * 0.025,
                            children: [
                              Container(
                                width: width * 0.203,
                                height: height * 0.093,
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
                                    if (hasUnreadChat)
                                      Positioned(
                                        top: height * 0.027,
                                        left: width * 0.111,
                                        height: height * 0.015,
                                        width: width * 0.033,
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
                                width: width * 0.203,
                                height: height * 0.093,
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
                                  onPressed: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final savedMapType = prefs.getString(
                                      'preferred_map',
                                    );
                                    final availableMaps =
                                        await MapLauncher.installedMaps;

                                    AvailableMap? preferredMap;
                                    try {
                                      preferredMap = availableMaps.firstWhere(
                                        (map) =>
                                            map.mapType.toString() ==
                                            savedMapType,
                                      );
                                    } catch (_) {
                                      preferredMap = null;
                                    }

                                    if (preferredMap != null &&
                                        context.mounted) {
                                      await preferredMap.showDirections(
                                        destination: Coords(
                                          navigateLat,
                                          navigateLong,
                                        ),
                                        destinationTitle: "Destination",
                                      );
                                      return;
                                    }
                                    if (availableMaps.isEmpty) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "No map apps installed",
                                            ),
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    if (context.mounted) {
                                      AvailableMap draftMap =
                                          availableMaps.first;
                                      showModalBottomSheet(
                                        backgroundColor:
                                            darkMode
                                                ? const Color.fromARGB(
                                                  255,
                                                  41,
                                                  41,
                                                  41,
                                                )
                                                : Colors.white,
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                            builder: (context, setModalState) {
                                              return SafeArea(
                                                child: SizedBox(
                                                  width: width,
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      width * 0.05,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      spacing: height * 0.01,
                                                      children: [
                                                        Text(
                                                          'Open with',
                                                          style:
                                                              GoogleFonts.notoSans(
                                                                fontSize:
                                                                    width *
                                                                    0.05,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                        ),

                                                        SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    width *
                                                                    0.03,
                                                                vertical:
                                                                    width *
                                                                    0.02,
                                                              ),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children:
                                                                availableMaps.map((
                                                                  map,
                                                                ) {
                                                                  final isSelected =
                                                                      draftMap
                                                                          .mapType ==
                                                                      map.mapType;
                                                                  return GestureDetector(
                                                                    onTap: () {
                                                                      setModalState(() {
                                                                        draftMap =
                                                                            map;
                                                                      });
                                                                    },
                                                                    onDoubleTap: () {
                                                                      map.showDirections(
                                                                        destination: Coords(
                                                                          navigateLat,
                                                                          navigateLong,
                                                                        ),
                                                                        destinationTitle:
                                                                            "Destination",
                                                                      );
                                                                      Navigator.pop(
                                                                        context,
                                                                      );
                                                                    },
                                                                    child: Container(
                                                                      width:
                                                                          width *
                                                                          0.203,
                                                                      height:
                                                                          height *
                                                                          0.093,
                                                                      margin: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            width *
                                                                            0.02,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            isSelected
                                                                                ? const Color.fromARGB(
                                                                                  134,
                                                                                  156,
                                                                                  155,
                                                                                  155,
                                                                                )
                                                                                : Colors.transparent,
                                                                        borderRadius: BorderRadius.circular(
                                                                          width *
                                                                              0.03,
                                                                        ),
                                                                      ),

                                                                      child: Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          ClipRRect(
                                                                            borderRadius: BorderRadius.circular(
                                                                              width *
                                                                                  0.019,
                                                                            ),
                                                                            child: SvgPicture.asset(
                                                                              map.icon,
                                                                              height:
                                                                                  height *
                                                                                  0.046,
                                                                              width:
                                                                                  width *
                                                                                  0.101,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                height *
                                                                                0.009,
                                                                          ),
                                                                          Text(
                                                                            map.mapName,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style: GoogleFonts.notoSans(
                                                                              fontSize:
                                                                                  width *
                                                                                  0.025,
                                                                              fontWeight:
                                                                                  FontWeight.w600,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                          ),
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          spacing: width * 0.05,

                                                          children: [
                                                            TextButton(
                                                              onPressed: () {
                                                                draftMap.showDirections(
                                                                  destination: Coords(
                                                                    navigateLat,
                                                                    navigateLong,
                                                                  ),
                                                                  destinationTitle:
                                                                      "Destination",
                                                                );
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                              },
                                                              child: Text(
                                                                "Just Once",
                                                                style: GoogleFonts.notoSans(
                                                                  fontSize:
                                                                      width *
                                                                      0.045,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      darkMode
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              width:
                                                                  width * 0.005,
                                                              height:
                                                                  height * 0.02,
                                                              decoration:
                                                                  BoxDecoration(
                                                                    color:
                                                                        const Color.fromARGB(
                                                                          134,
                                                                          156,
                                                                          155,
                                                                          155,
                                                                        ),
                                                                  ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () async {
                                                                await prefs.setString(
                                                                  'preferred_map',
                                                                  draftMap
                                                                      .mapType
                                                                      .toString(),
                                                                );
                                                                await draftMap.showDirections(
                                                                  destination: Coords(
                                                                    navigateLat,
                                                                    navigateLong,
                                                                  ),
                                                                  destinationTitle:
                                                                      "Destination",
                                                                );
                                                                if (context
                                                                    .mounted) {
                                                                  Navigator.pop(
                                                                    context,
                                                                  );
                                                                }
                                                              },
                                                              child: Text(
                                                                "Always",
                                                                style: GoogleFonts.notoSans(
                                                                  fontSize:
                                                                      width *
                                                                      0.045,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      darkMode
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
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
                                            },
                                          );
                                        },
                                      );
                                    }
                                  },
                                  icon: Transform.rotate(
                                    angle: 50 * (pi / 180),
                                    child: Icon(
                                      Icons.navigation_sharp,
                                      color: Colors.black,
                                      size: width * 0.101,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: height * 0.01),
                          Padding(
                            padding: EdgeInsets.all(width * 0.0203),
                            child: SwipeableButtonView(
                              onFinish: () async {
                                if (rideFlow.startRide &&
                                    startArrivedBool &&
                                    rideFlow.finishRide &&
                                    isWithinRange) {
                                } else if (rideFlow.startRide &&
                                    startArrivedBool &&
                                    isWithinRange) {
                                  setState(() {
                                    isFinished = false;
                                  });
                                } else if (rideFlow.startRide) {
                                  setState(() {
                                    isFinished = false;
                                  });
                                }
                              },
                              isActive:
                                  !rideFlow.startRide ||
                                  (rideFlow.startRide &&
                                      !startArrivedBool &&
                                      isWithinRange) ||
                                  (rideFlow.startRide &&
                                      startArrivedBool &&
                                      !rideFlow.pickGuest) ||
                                  (rideFlow.startRide &&
                                      startArrivedBool &&
                                      rideFlow.pickGuest &&
                                      isWithinRange),
                              isFinished: isFinished,
                              onWaitingProcess: () async {
                                if (!rideFlow.startRide) {
                                  rideFlowNotifier.setStartRide(true);
                                  setState(() {
                                    isFinished = true;
                                  });
                                } else if (rideFlow.startRide &&
                                    !startArrivedBool &&
                                    isWithinRange) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('Cars')
                                        .doc(docId)
                                        .set({
                                          'Routes': {
                                            routeKey!: {'Start Arrived': true},
                                          },
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        }, SetOptions(merge: true));
                                    setState(() {
                                      isFinished = true;
                                    });
                                  } on Exception catch (e) {
                                    logger.e('Error for startArrived: $e ');
                                  }
                                } else if (rideFlow.startRide &&
                                    startArrivedBool &&
                                    !rideFlow.pickGuest &&
                                    !rideFlow.finishRide) {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              width * 0.05,
                                            ),
                                          ),
                                          backgroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF2C2C2E)
                                                  : Colors.white,
                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.person_pin_circle_rounded,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: width * 0.025),
                                              Text(
                                                'Guest Pickup',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: width * 0.045,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            'Have you picked up the guest?',
                                            style: TextStyle(
                                              fontSize: width * 0.04,
                                            ),
                                          ),
                                          actionsPadding: EdgeInsets.symmetric(
                                            horizontal: width * 0.03,
                                            vertical: height * 0.009,
                                          ),
                                          actions: [
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    Colors.grey.shade600,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        width * 0.025,
                                                      ),
                                                ),
                                              ),
                                              icon: const Icon(Icons.close),
                                              label: const Text('Not yet'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        width * 0.025,
                                                      ),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.check_circle,
                                              ),
                                              label: const Text('Yes, picked'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (result == true) {
                                    rideFlowNotifier.guestPickedUp(true);
                                    final guestPickUpApi = GuestPickUpApi();
                                    guestPickUpApi.postData({"CarID": docId});
                                    setState(() {
                                      isFinished = true;
                                    });
                                  } else {
                                    rideFlowNotifier.guestPickedUp(false);
                                    setState(() {
                                      isFinished = true;
                                    });
                                  }
                                  _panelController.anchor();
                                } else if (rideFlow.startRide &&
                                    startArrivedBool &&
                                    isWithinRange &&
                                    !rideFlow.finishRide) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('Cars')
                                        .doc(docId)
                                        .set({
                                          'Routes': {
                                            routeKey!: {'End Arrived': true},
                                          },
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        }, SetOptions(merge: true));
                                    rideFlowNotifier.setFinishRide(true);
                                    setState(() {
                                      isFinished = true;
                                    });
                                    if (context.mounted) {
                                      await Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.fade,
                                          child: IntermediatePage(),
                                        ),
                                      );
                                    }
                                    rideFlowNotifier.resetAll();
                                    setState(() {
                                      isFinished = false;
                                    });
                                  } on Exception catch (e) {
                                    logger.e('Error for endArrived: $e ');
                                  }
                                }
                                _panelController.anchor();
                              },
                              activeColor:
                                  darkMode
                                      ? Color(0xFF0169AA)
                                      : Color(0xFF34A8EB),

                              buttonWidget: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.grey,
                              ),
                              buttonText: swipeButtonText,
                              buttontextstyle: GoogleFonts.notoSans(
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                                fontSize: width * 0.045,
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
