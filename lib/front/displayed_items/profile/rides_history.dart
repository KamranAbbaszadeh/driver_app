import 'package:driver_app/back/rides_history/rides_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RidesHistory extends ConsumerStatefulWidget {
  const RidesHistory({super.key});

  @override
  ConsumerState<RidesHistory> createState() => _RidesHistoryState();
}

class _RidesHistoryState extends ConsumerState<RidesHistory> {
  String? expandedTileKey;
  @override
  Widget build(BuildContext context) {
    final ridesState = ref.watch(ridesHistoryProvider);
    final allRides = ridesState.allRides;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final rideTours = allRides.where((ride) => ride.driver != '').toList();
    final guideTours = allRides.where((ride) => ride.guide != '').toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          hoverColor: Colors.transparent,
          icon: Icon(
            Icons.arrow_circle_left_rounded,
            size: width * 0.1,
            color: Colors.grey.shade400,
          ),
        ),
        toolbarHeight: height * 0.1,
        centerTitle: true,
        title: Text(
          "Rides History",
          style: GoogleFonts.ptSans(
            fontSize: width * 0.066,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          allRides.isEmpty
              ? Center(child: Text('No rides available.'))
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        darkMode
                            ? [Color.fromARGB(255, 1, 105, 170), Colors.black]
                            : [Color.fromARGB(255, 52, 168, 235), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(expandedTileKey),
                  child: ListView(
                    children: [
                      if (rideTours.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.035,
                            vertical: height * 0.009,
                          ),
                          child: Text(
                            "Ride Tours",
                            style: GoogleFonts.ptSans(
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: darkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        ...rideTours.asMap().entries.map((entry) {
                          final index = entry.key;
                          final ride = entry.value;
                          return buildRideCard(
                            context,
                            ride,
                            width,
                            height,
                            darkMode,
                            index,
                            'ride',
                          );
                        }),
                      ],
                      if (guideTours.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.035,
                            vertical: height * 0.009,
                          ),
                          child: Text(
                            "Guide Tours",
                            style: GoogleFonts.ptSans(
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: darkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        ...guideTours.asMap().entries.map((entry) {
                          final index = entry.key;
                          final ride = entry.value;
                          return buildRideCard(
                            context,
                            ride,
                            width,
                            height,
                            darkMode,
                            index,
                            'guide',
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  Widget buildRideCard(
    BuildContext context,
    dynamic ride,
    double width,
    double height,
    bool darkMode,
    int index,
    String section,
  ) {
    final formattedStart = DateFormat(
      'dd MMM yyyy HH:mm',
    ).format(ride.startDate);
    final formattedEnd = DateFormat('dd MMM yyyy HH:mm').format(ride.endDate);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: width * 0.035,
        vertical: height * 0.009,
      ),
      color:
          darkMode
              ? const Color.fromARGB(255, 81, 80, 80)
              : const Color.fromARGB(255, 201, 201, 201),
      shadowColor:
          darkMode
              ? const Color.fromARGB(255, 81, 80, 80)
              : const Color.fromARGB(255, 201, 201, 201),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(width * 0.03),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.03),
        child: ExpansionTile(
          onExpansionChanged: (isExpanded) {
            if (isExpanded) {
              setState(() => expandedTileKey = ride.docId);
            } else {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && expandedTileKey == ride.docId) {
                  setState(() => expandedTileKey = null);
                }
              });
            }
          },
          initiallyExpanded: expandedTileKey == ride.docId,
          tilePadding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.009,
          ),

          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ride.tourName,
                style: GoogleFonts.cabin(
                  fontSize: width * 0.052,
                  fontWeight: FontWeight.bold,
                  color: darkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                " \$${ride.price.toStringAsFixed(2)}",
                style: GoogleFonts.cabin(
                  fontSize: width * 0.037,
                  fontWeight: FontWeight.bold,
                  color: darkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          shape: Border(
            bottom: BorderSide.none,
            left: BorderSide.none,
            right: BorderSide.none,
            top: BorderSide.none,
          ),
          iconColor: darkMode ? Colors.white : Colors.black,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Guests: ",
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.037,
                                  fontWeight: FontWeight.bold,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: ride.numOfGuests.toString(),
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.normal,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Routes: ",
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.037,
                                  fontWeight: FontWeight.bold,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: ride.numOfRoutes.toString(),
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.normal,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Distance: ",
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.037,
                                  fontWeight: FontWeight.bold,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              TextSpan(
                                text:
                                    "${ride.totalDistanceKm.toStringAsFixed(2)} km",
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.normal,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    section == 'ride'
                                        ? "Vehicle Type:  "
                                        : "Category:  ",
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.037,
                                  fontWeight: FontWeight.bold,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              TextSpan(
                                text:
                                    section == 'ride'
                                        ? ride.vehicleType
                                        : ride.category,
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.normal,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Start: ",
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.037,
                                  fontWeight: FontWeight.bold,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: formattedStart,
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.normal,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "End: ",
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.037,
                                  fontWeight: FontWeight.bold,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: formattedEnd,
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.normal,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Paid:  ",
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.037,
                                  fontWeight: FontWeight.bold,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: ride.isPaid ? 'Yes' : 'No',
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.normal,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: height * 0.01),
                      ],
                    ),
                    Icon(
                      Icons.check_circle,
                      size: width * 0.3,
                      color:
                          ride.isCompleted
                              ? ride.isPaid
                                  ? const Color.fromARGB(255, 103, 168, 120)
                                  : const Color.fromARGB(255, 231, 1, 55)
                              : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
