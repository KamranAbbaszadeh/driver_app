import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/user_assign.dart/user_assign.dart';
import 'package:onemoretour/front/tools/date_picker.dart';
import 'package:onemoretour/front/displayed_items/tours/ride_routes.dart';
import 'package:onemoretour/front/tools/ride_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late final String carName;
  late final String vehicleRegistrationNumber;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? vehicleData;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.ride.startDate.toDate();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userId = user.uid;

      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .get();
      if (docSnapshot.exists && mounted) {
        setState(() {
          userData = docSnapshot.data();
          carName = userData!['Active Vehicle'] ?? '';
        });
      }
      final vehicleDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .collection('Vehicles')
              .doc(carName)
              .get();

      if (docSnapshot.exists && mounted) {
        setState(() {
          vehicleData = vehicleDoc.data();
          vehicleRegistrationNumber =
              vehicleDoc['Vehicle Registration Number'] ?? '';
        });
      }
    } catch (e) {
      logger.e('Error fetching user\'s data: $e');
    }
  }

  void updateSelectedDay(DateTime day) {
    if (mounted) {
      setState(() {
        selectedDay = day;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final detailList = widget.ride.routes;

    final sortedEntries =
        detailList.entries.where((entry) {
            DateTime startDate = DateTime.parse(entry.value['StartDate']);
            return isSameDay(startDate, selectedDay);
          }).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    List<Map<String, dynamic>> matchingRoutes =
        sortedEntries.map((e) => e.value as Map<String, dynamic>).toList();

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(
              context: context,
              width: width,
              height: height,
              darkMode: darkMode,
            ),
            Container(
              height: height * 0.74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(width * 0.076),
                  topRight: Radius.circular(width * 0.076),
                ),
                gradient: LinearGradient(
                  colors:
                      darkMode
                          ? [Color.fromARGB(255, 1, 105, 170), Colors.black]
                          : [Color.fromARGB(255, 52, 168, 235), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  tileMode: TileMode.decal,
                ),
              ),
              child: Column(
                children: [
                  DatePicker(
                    ride: widget.ride,
                    updateSelectedDay: updateSelectedDay,
                  ),
                  matchingRoutes.isEmpty
                      ? Text('No routes for Today!')
                      : Flexible(
                        child: ListView.builder(
                          itemCount: matchingRoutes.length,
                          shrinkWrap: true,
                          padding: EdgeInsets.all(0),
                          itemBuilder:
                              (context, index) =>
                                  RideRoutes(detail: matchingRoutes[index]),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar({
    required BuildContext context,
    required double height,
    required double width,
    required bool darkMode,
  }) {
    if (userData == null) {
      return Center(child: CircularProgressIndicator());
    }
    final baseUrl =
        userData!['Role'] == 'Guide'
            ? 'https://onemoretour.com/version-test/api/1.1/wf/assign-guide'
            : 'https://onemoretour.com/version-test/api/1.1/wf/assign-driver';
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: darkMode ? Colors.black : Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_ios, size: width * 0.05),
      ),
      title: Text(
        widget.ride.tourName,
        maxLines: 2,
        style: GoogleFonts.daysOne(
          fontSize: width * 0.076,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      toolbarHeight: height * 0.15,
      actionsPadding: EdgeInsets.all(width * 0.03),
      actions: [
        widget.ride.driver == ''
            ? GestureDetector(
              onTap: () async {
                userAssign(
                  docId: widget.ride.docId,
                  baseUrl: baseUrl,
                  collection: widget.ride.collectionSource!,
                  carName: carName,
                  vehicleRegistrationNumber: vehicleRegistrationNumber,
                  tourEdnDAte: widget.ride.endDate,
                );
              },
              child: Container(
                width: width * 0.22,
                height: height * 0.035,
                decoration: BoxDecoration(
                  color:
                      darkMode
                          ? Color.fromARGB(255, 1, 105, 170)
                          : Color.fromARGB(255, 52, 168, 235),
                  borderRadius: BorderRadius.circular(width * 0.01),
                ),
                padding: EdgeInsets.all(width * 0.01),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      'Get a Ride',
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w600,
                        color: darkMode ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
            : SizedBox.shrink(),
      ],
    );
  }
}
