import 'package:driver_app/back/map_and_location/get_functions.dart';
import 'package:driver_app/front/consts.dart';
import 'package:driver_app/front/get_location_name.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  LatLng? startLatLngObj;
  LatLng? endLatLngObj;

  GoogleMapController? mapController;
  Map<PolylineId, Polyline> polylines = {};
  CameraPosition? initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _fetchLocationNames();
  }

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

  Future<void> _fetchLocationNames() async {
    try {
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

        initialCameraPosition = CameraPosition(target: midpoint, zoom: 7.0);

        getPolyLinePoints(
          googleApiKey: GOOGLE_MAPS_API_KEY,
          source: startLatLngObj!,
          destination: endLatLngObj!,
        ).then(
          (coordinates) => generatePolyLineFromPoints(
            polylineCoordinates: coordinates,
            polylines: polylines,
            updatePolylines: (updatedPolylines) {
              setState(() {
                polylines = updatedPolylines;
              });
            },
          ),
        );
      });
    } catch (e) {
      setState(() {
        startLocationName = "Error fetching start location";
        endLocationName = "Error fetching end location";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Center(
      child:
          widget.detail.isEmpty
              ? const Center(child: Text("No routes for today"))
              : isLoading
              ? const CircularProgressIndicator()
              : Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.038),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        darkMode
                            ? [
                              Color.fromARGB(255, 1, 105, 170),
                              Color.fromARGB(255, 0, 0, 0),
                            ]
                            : [Color.fromARGB(255, 52, 168, 235), Colors.white],
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    startLocationName != null ||
                            startLatLngObj != null ||
                            endLocationName != null ||
                            endLatLngObj != null
                        ? buildFieldContainer(
                          startTitle: '* Start Location: ',
                          startDescription: startLocationName!,
                          startlocation: startLatLngObj!,
                          endTitle: '* End Location: ',
                          endDescription: endLocationName!,
                          endlocation: endLatLngObj!,
                        )
                        : SizedBox.shrink(),
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
  }) {
    if (initialCameraPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(7.5)),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: startTitle,
              style: GoogleFonts.cabin(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: startDescription,
                  style: GoogleFonts.cabin(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          RichText(
            text: TextSpan(
              text: endTitle,
              style: GoogleFonts.cabin(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: endDescription,
                  style: GoogleFonts.cabin(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 400,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7.5),
              child: GoogleMap(
                initialCameraPosition: initialCameraPosition!,
                mapType: MapType.normal,
                trafficEnabled: true,
                onMapCreated: (controller) {
                  mapController = controller;
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
