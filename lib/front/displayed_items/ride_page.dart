import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/map_and_location/location_provider.dart';
import 'package:driver_app/back/map_and_location/ride_flow_provider.dart';
import 'package:driver_app/front/displayed_items/chat_page.dart';
import 'package:driver_app/front/displayed_items/intermediate_page.dart';
import 'package:driver_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sliding_panel/flutter_sliding_panel.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:driver_app/back/ride/ride_state.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';

class RidePage extends ConsumerStatefulWidget {
  const RidePage({super.key});

  @override
  ConsumerState<RidePage> createState() => _RidePageState();
}

class _RidePageState extends ConsumerState<RidePage>
    with TickerProviderStateMixin {
  final SlidingPanelController _panelController = SlidingPanelController();
  StreamSubscription? _locationSubscription;
  late final AnimatedMapController _animatedMapController;
  bool _userInteractingWithMap = false;
  Timer? _interactionDebounce;

  bool isFinished = false;

  @override
  void initState() {
    super.initState();

    _animatedMapController = AnimatedMapController(vsync: this);
    _locationSubscription = FlutterBackgroundService()
        .on('LocationUpdates')
        .listen((event) {
          if (event != null) {
            ref.read(locationProvider.notifier).state = event;
          }
        });
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

  @override
  void dispose() {
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

    LatLng currentLocation = LatLng(
      position['latitude'],
      position['longitude'],
    );

    dynamic currentHeading = position['heading'];

    final midPoint = getMidpoint(startLatLng, endLatLng, currentLocation);
    final distance = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      endLatLng.latitude,
      endLatLng.longitude,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_userInteractingWithMap) {
        final currentCenter =
            _animatedMapController.mapController.camera.center;
        if (currentCenter != currentLocation) {
          _animatedMapController.animateTo(
            dest: currentLocation,
            zoom: width * 0.034,
            curve: Curves.easeInOut,
            duration: Duration(milliseconds: 500),
          );
        }
      }
    });
    final zoomLvl = getZoomLevel(distance);
    final startArrivedBool = rideState.startArrived;
    final routeKey = rideState.routeKey;
    final rideFlow = ref.watch(rideFlowProvider);
    final rideFlowNotifier = ref.read(rideFlowProvider.notifier);
    final swipeButtonText =
        rideFlow.startRide
            ? startArrivedBool!
                ? "Complete the ride"
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

    final bool isWithinRange = distanceToTarget <= 50;
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
                    SizedBox(
                      child: FlutterMap(
                        mapController: _animatedMapController.mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            midPoint.latitude,
                            midPoint.longitude,
                          ),
                          initialZoom: zoomLvl,
                          onMapEvent: (event) {
                            if (event is MapEventWithMove) {
                              _userInteractingWithMap = true;
                              _interactionDebounce?.cancel();
                              _interactionDebounce = Timer(
                                const Duration(seconds: 2),
                                () {
                                  _userInteractingWithMap = false;
                                },
                              );
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentLocation,
                                rotate: true,
                                alignment: Alignment.center,
                                width: width * 0.1,
                                height: height * 0.1,
                                child: Transform.rotate(
                                  angle: currentHeading * (pi / 180),
                                  child: Image.asset(
                                    'assets/Car.png',
                                    width: width * 0.1,
                                    height: height * 0.1,
                                  ),
                                ),
                              ),
                              Marker(
                                point: startLatLng,
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
                                point: endLatLng,
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
                              SizedBox(width: width * 0.203),
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
                                  borderRadius: BorderRadius.circular(
                                    width * 0.05,
                                  ),
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
                                  spacing: width * 0.05,
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
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
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
                                    startArrivedBool! &&
                                    rideFlow.finishRide &&
                                    isWithinRange) {
                                  await Navigator.push(
                                    context,
                                    PageTransition(
                                      type: PageTransitionType.fade,
                                      child: IntermediatePage(),
                                    ),
                                  );
                                  rideFlowNotifier.resetAll();
                                  setState(() {
                                    isFinished = false;
                                  });
                                } else if (rideFlow.startRide &&
                                    startArrivedBool! &&
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
                                  rideFlow.startRide ? isWithinRange : true,
                              isFinished: isFinished,
                              onWaitingProcess: () async {
                                if (!rideFlow.startRide) {
                                  rideFlowNotifier.setStartRide(true);
                                  setState(() {
                                    isFinished = true;
                                  });
                                } else if (rideFlow.startRide &&
                                    !startArrivedBool! &&
                                    isWithinRange) {
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
                                } else if (rideFlow.startRide &&
                                    startArrivedBool! &&
                                    isWithinRange &&
                                    !rideFlow.finishRide) {
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
                                }
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
