// Screen displaying the user's ride history.
// Separates and displays tours where the user was a driver and those where they were a guide.
// Uses animated expansion tiles for detailed ride information.
import 'package:onemoretour/back/rides_history/rides_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// A custom expansion tile widget with animated expand/collapse behavior.
/// Replaces the default [ExpansionTile] with a smoother animation.
class CustomExpansionTile extends StatefulWidget {
  final Widget title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggles the expansion state and triggers animation.
  void toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: widget.title,
          trailing: RotationTransition(
            turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
            child: Icon(Icons.expand_more),
          ),
          onTap: toggleExpansion,
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: 1.0,
          child: Column(children: widget.children),
        ),
      ],
    );
  }
}

/// Main screen showing the user's full history of completed ride and guide tours.
/// Fetches data via a Riverpod provider and categorizes entries.
class RidesHistory extends ConsumerStatefulWidget {
  const RidesHistory({super.key});

  @override
  ConsumerState<RidesHistory> createState() => _RidesHistoryState();
}

class _RidesHistoryState extends ConsumerState<RidesHistory> {
  String? expandedTileKey;

  /// Builds the main layout of the ride history screen, including ride and guide tour sections.
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
        surfaceTintColor: Colors.transparent,
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
                          // Section header for Ride Tours
                          child: Text(
                            "Ride Tours",
                            style: GoogleFonts.ptSans(
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: darkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        // Generate a list of ride cards for the given tour type.
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
                          // Section header for Guide Tours
                          child: Text(
                            "Guide Tours",
                            style: GoogleFonts.ptSans(
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: darkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        // Generate a list of ride cards for the given tour type.
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

  /// Builds a card with expandable detailed information for each ride or guide tour.
  /// Dynamically adjusts label based on section (ride or guide).
  Widget buildRideCard(
    BuildContext context,
    dynamic ride,
    double width,
    double height,
    bool darkMode,
    int index,
    String section,
  ) {
    // Format the start and end date for display.
    final formattedStart = DateFormat(
      'dd MMM yyyy HH:mm',
    ).format(ride.startDate);
    final formattedEnd = DateFormat('dd MMM yyyy HH:mm').format(ride.endDate);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: width * 0.035,
        vertical: height * 0.009,
      ),
      color: darkMode ? const Color(0xFF2C2C2C) : Colors.white,
      shadowColor: Colors.black.withAlpha((255 * 0.2).toInt()),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(width * 0.05),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.05),
        child: CustomExpansionTile(
          initiallyExpanded: expandedTileKey == ride.docId,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: width * 0.55,
                child: Text(
                  ride.tourName,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cabin(
                    fontSize: width * 0.052,
                    fontWeight: FontWeight.bold,
                    color: darkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Text(
                " \$${ride.price.toStringAsFixed(1)}",
                style: GoogleFonts.cabin(
                  fontSize: width * 0.037,
                  fontWeight: FontWeight.bold,
                  color: darkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
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
                        ride.fine > 0
                            ? Column(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Fine:  ",
                                        style: GoogleFonts.cabin(
                                          fontSize: width * 0.037,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              darkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            "\$${ride.fine.toStringAsFixed(1)}",
                                        style: GoogleFonts.cabin(
                                          fontSize: width * 0.035,
                                          fontWeight: FontWeight.normal,
                                          color:
                                              darkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: height * 0.01),
                              ],
                            )
                            : const SizedBox.shrink(),
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
