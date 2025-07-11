// Displays detailed route information for a tour, including start and end locations.
// Shows the tour path on a styled Google Map with start/end markers and a polyline route.

import 'dart:async';

import 'package:onemoretour/back/map_and_location/google_map_controllers.dart';
import 'package:onemoretour/front/tools/consts.dart';
import 'package:onemoretour/front/tools/get_location_name.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

/// Widget that displays tour route information for a given tour detail.
/// Shows start/end locations, date, and renders a Google Map with route preview.
class RideRoutes extends StatefulWidget {
  final Map<String, dynamic> detail;
  const RideRoutes({super.key, required this.detail});

  @override
  State<RideRoutes> createState() => _RideRoutesState();
}

class _RideRoutesState extends State<RideRoutes> {
  String? startLocationName;
  String? endLocationName;
  bool isLoading = true;
  String? startDate;

  LatLng? startLatLngObj;
  LatLng? endLatLngObj;

  GoogleMapController? mapController;
  Map<PolylineId, Polyline> polylines = {};
  CameraPosition? initialCameraPosition;
  late String _mapStyleDarkString;
  late String _mapStyleLightString;
  bool _isControllerDisposed = false;

  /// Loads the location names and map styles during widget initialization.
  @override
  void initState() {
    super.initState();
    _fetchLocationNames();
    DefaultAssetBundle.of(
      context,
    ).loadString('assets/map_style_dark.json').then((value) {
      if (mounted) {
        setState(() {
          _mapStyleDarkString = value;
        });
      }
    });
    DefaultAssetBundle.of(
      context,
    ).loadString('assets/map_style_light.json').then((value) {
      if (mounted) {
        setState(() {
          _mapStyleLightString = value;
        });
      }
    });
  }

  /// Disposes the Google Map controller safely to prevent memory leaks.
  @override
  void dispose() {
    if (mapController != null && !_isControllerDisposed) {
      mapController!.dispose();
      _isControllerDisposed = true;
    }

    super.dispose();
  }

  /// Re-fetches location names if the widget's tour detail changes.
  @override
  void didUpdateWidget(covariant RideRoutes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.detail != oldWidget.detail) {
      _fetchLocationNames();
    }
  }

  LatLng getMidpoint(LatLng start, LatLng end) {
    double midLat = (start.latitude + end.latitude) / 2;
    double midLng = (start.longitude + end.longitude) / 2;

    return LatLng(midLat, midLng);
  }

  /// Converts coordinate strings to readable location names and sets map positions.
  /// Also fetches polyline route between start and end locations.
  Future<void> _fetchLocationNames() async {
    try {
      // Skip processing if no route detail provided.
      if (widget.detail.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
      String startCoordinates = widget.detail['Start'];
      String endCoordinates = widget.detail['End'];

      List<String> startLatLng = startCoordinates.split(",");
      List<String> endLatLng = endCoordinates.split(",");

      double startLat = double.parse(startLatLng[0]);
      double startLng = double.parse(startLatLng[1]);

      double endLat = double.parse(endLatLng[0]);
      double endLng = double.parse(endLatLng[1]);

      String startName = await getLocationName(startLat, startLng);
      String endName = await getLocationName(endLat, endLng);

      if (mounted) {
        setState(() {
          startLocationName = startName;
          endLocationName = endName;
          isLoading = false;
          startLatLngObj = LatLng(startLat, startLng);
          endLatLngObj = LatLng(endLat, endLng);

          LatLng midpoint = getMidpoint(startLatLngObj!, endLatLngObj!);

          if (mapController != null && startLatLngObj != null) {
            mapController!.animateCamera(CameraUpdate.newLatLng(midpoint));
          }

          // Format and store the start date for display.
          final DateTime rawStartDate = DateTime.parse(
            widget.detail['StartDate'],
          );
          startDate = DateFormat('dd MMMM yyyy, HH:mm').format(rawStartDate);

          initialCameraPosition = CameraPosition(target: midpoint, zoom: 7.0);
        });
      }
      getPolyLinePoints(
        googleApiKey: GOOGLE_MAPS_API_KEY,
        source: startLatLngObj!,
        destination: endLatLngObj!,
      ).then(
        (coordinates) => generatePolyLineFromPoints(
          polylineCoordinates: coordinates,
          polylines: polylines,
          updatePolylines: (updatedPolylines) {
            if (!mounted) return;
            setState(() {
              polylines = updatedPolylines;
            });
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          startLocationName = "Error fetching start location";
          endLocationName = "Error fetching end location";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Display loading spinner or route content once ready.
    return Center(
      child:
          isLoading
              ? const CircularProgressIndicator()
              : Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.038),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.date_range_rounded),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'Start Date: ',
                              style: GoogleFonts.cabin(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.04,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color!,
                              ),
                              children: [
                                TextSpan(
                                  text: startDate,
                                  style: GoogleFonts.cabin(
                                    fontWeight: FontWeight.w400,
                                    fontSize: width * 0.04,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color!,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.011),
                    startLocationName != null ||
                            startLatLngObj != null ||
                            endLocationName != null ||
                            endLatLngObj != null
                        ? buildFieldContainer(
                          startTitle: 'Start Location: ',
                          startDescription: startLocationName!,
                          startlocation: startLatLngObj!,
                          endTitle: 'End Location: ',
                          endDescription: endLocationName!,
                          endlocation: endLatLngObj!,
                          startIcon: Icon(
                            Icons.location_on_rounded,
                            color: Colors.blue,
                          ),
                          endIcon: Icon(
                            Icons.location_on_rounded,
                            color: Colors.red,
                          ),
                          heigt: height,
                          width: width,
                          darkMode: darkMode,
                        )
                        : SizedBox.shrink(),
                    SizedBox(height: height * 0.058),
                  ],
                ),
              ),
    );
  }

  Widget buildFieldContainer({
    required String startTitle,
    required String startDescription,
    required String endTitle,
    required String endDescription,
    required LatLng startlocation,
    required LatLng endlocation,
    required Icon startIcon,
    required Icon endIcon,
    required double heigt,
    required double width,
    required bool darkMode,
  }) {
    if (initialCameraPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.019),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              startIcon,
              Expanded(
                child: RichText(
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  text: TextSpan(
                    text: startTitle,
                    style: GoogleFonts.cabin(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.04,
                      color: Theme.of(context).textTheme.bodyMedium?.color!,
                    ),
                    children: [
                      TextSpan(
                        text: startDescription,
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.w400,
                          fontSize: width * 0.04,
                          color: Theme.of(context).textTheme.bodyMedium?.color!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: heigt * 0.011),
          Row(
            children: [
              endIcon,
              Expanded(
                child: RichText(
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  text: TextSpan(
                    text: endTitle,
                    style: GoogleFonts.cabin(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.04,
                      color: Theme.of(context).textTheme.bodyMedium?.color!,
                    ),
                    children: [
                      TextSpan(
                        text: endDescription,
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.w400,
                          fontSize: width * 0.04,
                          color: Theme.of(context).textTheme.bodyMedium?.color!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: heigt * 0.023),
          SizedBox(
            height: heigt * 0.469,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.019),
              child:
              // Render the styled map with markers and route polyline.
              GoogleMap(
                initialCameraPosition: initialCameraPosition!,
                mapType: MapType.normal,
                myLocationButtonEnabled: false,
                style: darkMode ? _mapStyleDarkString : _mapStyleLightString,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                tiltGesturesEnabled: true,
                markers: {
                  Marker(
                    markerId: MarkerId('startLocation'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),

                    position: startlocation,
                  ),
                  Marker(
                    markerId: MarkerId('endLocation'),
                    icon: BitmapDescriptor.defaultMarker,

                    position: endlocation,
                  ),
                },

                polylines: Set<Polyline>.of(polylines.values),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
