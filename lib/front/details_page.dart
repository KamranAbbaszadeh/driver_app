import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/front/date_picker.dart';
import 'package:driver_app/front/ride_routes.dart';
import 'package:driver_app/front/tools/ride_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class DetailsPage extends StatefulWidget {
  final Ride ride;
  const DetailsPage({super.key, required this.ride});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late DateTime selectedDay;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.ride.startDate.toDate();
  }

  void updateSelectedDay(DateTime day) {
    setState(() {
      selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final detailList = widget.ride.routes;

    List<Map<String, dynamic>> matchingRoutes =
        detailList.values
            .where((route) {
              Timestamp date = route['StartDate'];
              DateTime startDate = date.toDate();
              return isSameDay(startDate, selectedDay);
            })
            .cast<Map<String, dynamic>>()
            .toList();

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(
            context: context,
            heigt: height,
            width: width,
            darkMode: darkMode,
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(width * 0.076),
                  topRight: Radius.circular(width * 0.076),
                ),
                color:
                    darkMode
                        ? Color.fromARGB(255, 1, 105, 170)
                        : Color.fromARGB(255, 52, 168, 235),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  DatePicker(
                    ride: widget.ride,
                    updateSelectedDay: updateSelectedDay,
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return RideRoutes(detail: matchingRoutes[index]);
            }, childCount: matchingRoutes.length),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar({
    required BuildContext context,
    required double heigt,
    required double width,
    required bool darkMode,
  }) {
    return SliverAppBar(
      expandedHeight: heigt * 0.1,
      backgroundColor: darkMode ? Colors.black : Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_ios, size: width * 0.05),
      ),
      actions: [Icon(Icons.more_vert, size: width * 0.101)],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.only(bottom: heigt * 0.045),
        title: Text(
          widget.ride.tourName,
          style: GoogleFonts.daysOne(
            fontSize: width * 0.055,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
