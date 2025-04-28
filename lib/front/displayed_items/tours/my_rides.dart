import 'package:driver_app/front/displayed_items/tours/details_page.dart';
import 'package:driver_app/front/tools/ride_model.dart';
import 'package:expandable_section/expandable_section.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MyRides extends StatefulWidget {
  final List<Ride> filteredRides;
  final ScrollController parentScrollController;
  const MyRides({
    super.key,
    required this.filteredRides,
    required this.parentScrollController,
  });

  @override
  State<MyRides> createState() => _MyRidesState();
}

class _MyRidesState extends State<MyRides> {
  final Set<int> expandedIndices = {};
  @override
  void initState() {
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return widget.filteredRides.isNotEmpty
        ? ListView.builder(
          controller: null,
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          itemCount: widget.filteredRides.length,

          shrinkWrap: true,
          itemBuilder:
              (context, index) => _buildRide(
                context: context,
                darkMode: darkMode,
                height: height,
                width: width,
                ride: widget.filteredRides[index],
                index: index,
              ),
        )
        : Center(
          child: Text(
            'You don\'t have any Rides.\nNavigate to Rides page and grab some',
            textAlign: TextAlign.center,
            style: GoogleFonts.ptSans(),
          ),
        );
  }

  Widget _buildRide({
    required BuildContext context,
    required Ride ride,
    required double height,
    required double width,
    required bool darkMode,
    required int index,
  }) {
    final tourStartDate = DateFormat(
      'dd MMMM yyyy, HH:mm',
    ).format(ride.startDate.toDate());

    final tourEndDate = DateFormat(
      'dd MMMM yyyy, HH:mm',
    ).format(ride.endDate.toDate());

    final isExpanded = expandedIndices.contains(index);

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final willExpand = !isExpanded;

            setState(() {
              if (isExpanded) {
                expandedIndices.remove(index);
              } else {
                expandedIndices.clear();
                expandedIndices.add(index);
              }
            });
            if (willExpand &&
                widget.filteredRides.length > 1 &&
                index == widget.filteredRides.length - 1) {
              Future.delayed(const Duration(milliseconds: 400), () {
                if (widget.parentScrollController.hasClients) {
                  widget.parentScrollController.animateTo(
                    widget.parentScrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                }
              });
            }

            if (!willExpand &&
                widget.filteredRides.length > 1 &&
                index == widget.filteredRides.length - 1) {
              Future.delayed(const Duration(milliseconds: 400), () {
                if (widget.parentScrollController.hasClients) {
                  widget.parentScrollController.animateTo(
                    widget.parentScrollController.offset - 250,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          },

          child: Container(
            padding:
                isExpanded
                    ? EdgeInsets.only(
                      left: width * 0.033,
                      right: width * 0.033,
                      top: width * 0.033,
                    )
                    : EdgeInsets.all(width * 0.033),
            width: width,
            decoration: BoxDecoration(
              color: darkMode ? Colors.black54 : Colors.white38,
              borderRadius:
                  isExpanded
                      ? BorderRadius.only(
                        topLeft: Radius.circular(width * 0.012),
                        topRight: Radius.circular(width * 0.012),
                      )
                      : BorderRadius.circular(width * 0.012),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.tourName,
                      style: GoogleFonts.ptSans(
                        fontWeight: FontWeight.w600,
                        fontSize: width * 0.045,
                        color: Theme.of(context).textTheme.bodyMedium?.color!,
                      ),
                    ),
                    SizedBox(height: height * 0.005),
                    RichText(
                      text: TextSpan(
                        text: 'Start Date: ',
                        style: GoogleFonts.ptSans(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyMedium?.color!,
                        ),
                        children: [
                          TextSpan(
                            text: tourStartDate,
                            style: GoogleFonts.ptSans(
                              fontWeight: FontWeight.w500,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color!,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),
        ),

        ExpandableSection(
          expand: isExpanded,
          curve: Curves.easeOut,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 0,
              maxHeight: double.infinity,
            ),
            child: Container(
              padding: EdgeInsets.only(
                left: width * 0.033,
                right: width * 0.033,
                bottom: width * 0.033,
              ),
              width: width,
              decoration: BoxDecoration(
                color: darkMode ? Colors.black54 : Colors.white38,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(width * 0.012),
                  bottomRight: Radius.circular(width * 0.012),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.005),
                      RichText(
                        text: TextSpan(
                          text: 'End Date: ',
                          style: GoogleFonts.ptSans(
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color!,
                          ),
                          children: [
                            TextSpan(
                              text: tourEndDate,
                              style: GoogleFonts.ptSans(
                                fontWeight: FontWeight.w500,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      RichText(
                        text: TextSpan(
                          text: 'Numer of Guest: ',
                          style: GoogleFonts.ptSans(
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color!,
                          ),
                          children: [
                            TextSpan(
                              text: ride.numOfGuests.toString(),
                              style: GoogleFonts.ptSans(
                                fontWeight: FontWeight.w500,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      RichText(
                        text: TextSpan(
                          text: 'Price: ',
                          style: GoogleFonts.ptSans(
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color!,
                          ),
                          children: [
                            TextSpan(
                              text: '\$${ride.price.toString()} ',
                              style: GoogleFonts.ptSans(
                                fontWeight: FontWeight.w500,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.005),

                      GestureDetector(
                        onTap: () {
                          expandedIndices.remove(index);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DetailsPage(ride: ride),
                            ),
                          );
                        },
                        child: Container(
                          width: width * 0.508,
                          height: height * 0.046,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(width * 0.019),
                            color:
                                darkMode
                                    ? Color.fromARGB(255, 52, 168, 235)
                                    : Color.fromARGB(255, 1, 105, 170),
                          ),
                          child: Center(
                            child: Text(
                              'See Ride Details',
                              style: GoogleFonts.daysOne(
                                fontWeight: FontWeight.w600,
                                color: darkMode ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: height * 0.005),
        index == widget.filteredRides.length - 1 && isExpanded
            ? SizedBox(height: height * 0.08)
            : SizedBox.shrink(),
      ],
    );
  }
}
