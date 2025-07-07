// A card widget that displays detailed information about a registered vehicle.
// Includes registration number, name, type, category, seat count, and manufacturing year.
// Visual state updates based on approval and selection.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Displays a vehicle card with key attributes and icon representation.
/// Highlights the active vehicle and responds to user interaction if approved.
class VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final bool isApproved;
  final double width;
  final double height;
  final bool darkMode;
  final Map<String, String> vehicleTypeIcons;
  final VoidCallback onTap;
  final ValueNotifier<String?> activeVehicleIdNotifier;
  const VehicleCard({
    required this.vehicle,
    required this.isApproved,
    required this.width,
    required this.height,
    required this.darkMode,
    required this.vehicleTypeIcons,
    required this.onTap,
    required this.activeVehicleIdNotifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: activeVehicleIdNotifier,
      builder: (context, activeVehicleId, _) {
        // Determine if this vehicle is currently selected based on the active ID.
        final isSelected =
            activeVehicleId != null && vehicle['docId'] == activeVehicleId;
        // Extract seat number and vehicle details safely with fallbacks.
        final seatNumber = vehicle['Seat Number']?.toString() ?? '-';
        final vehicleYear = vehicle['Vehicle\'s Year']?.toString() ?? '-';
        final vehicleCategory = vehicle['Vehicle Category']?.toString() ?? '-';
        // Make the card tappable only if vehicle is approved and not already selected.
        return InkWell(
          onTap: isApproved && !isSelected ? onTap : () {},
          // Animate scaling of the card for visual feedback when selected.
          child: AnimatedScale(
            scale: isSelected ? 1.05 : 1.0,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: Card(
              margin: EdgeInsets.symmetric(
                horizontal: width * 0.04,
                vertical: height * 0.009,
              ),
              elevation: width * 0.025,
              shadowColor: Colors.black.withAlpha((255 * 0.1).toInt()),
              color:
                  isApproved
                      ? (darkMode ? const Color(0xFF2C2C2C) : Colors.white)
                      : (darkMode
                          ? const Color(0xFF424242)
                          : const Color.fromARGB(255, 167, 167, 167)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(width * 0.05),
              ),
              // Smoothly animate background color changes and border styling.
              child: AnimatedContainer(
                duration: Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color:
                      isApproved
                          ? (darkMode ? const Color(0xFF2C2C2C) : Colors.white)
                          : (darkMode
                              ? const Color(0xFF424242)
                              : const Color.fromARGB(255, 167, 167, 167)),
                  borderRadius: BorderRadius.circular(width * 0.05),
                ),
                child: Padding(
                  padding: EdgeInsets.all(width * 0.03),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Display vehicle icon based on its type.
                          Image.asset(
                            vehicleTypeIcons[vehicle['Vehicle\'s Type']] ??
                                'assets/car_icons/sedan.png',
                            width: width * 0.1,
                            height: width * 0.1,
                            color: darkMode ? Colors.white : Colors.black,
                          ),
                          SizedBox(width: width * 0.04),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Show the vehicle's registration number in bold.
                              Text(
                                vehicle['Vehicle Registration Number'] ??
                                    'Unknown',
                                style: GoogleFonts.ptSans(
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              RichText(
                                // Render multiple vehicle details using labeled spans.
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: 'Vehicle: ',
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.035,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '${vehicle['Vehicle Name'] ?? 'Unknown'}\n',
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.033,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Type: ',
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.035,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          (vehicle['Vehicle\'s Type'] ??
                                              'Unknown type') +
                                          '\n',
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.033,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Category: ',
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.035,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$vehicleCategory\n',
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.033,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Seats: ',
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.035,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$seatNumber\n',
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.033,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Year: ',
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.035,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: vehicleYear,
                                      style: GoogleFonts.cabin(
                                        fontSize: width * 0.033,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: height * 0.004),
                            ],
                          ),
                        ],
                      ),
                      // Show "Active" badge when this vehicle is the currently selected one.
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child:
                            isSelected
                                ? Container(
                                  key: ValueKey('activeBadge'),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.02,
                                    vertical: height * 0.004,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      103,
                                      168,
                                      120,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      width * 0.03,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        size: width * 0.04,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: width * 0.01),
                                      Text(
                                        "Active",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: width * 0.03,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
