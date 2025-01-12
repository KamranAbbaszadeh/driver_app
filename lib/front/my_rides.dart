import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/front/details_page.dart';
import 'package:driver_app/front/tools/ride_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class MyRides extends StatefulWidget {
  const MyRides({super.key});

  @override
  State<MyRides> createState() => _MyRidesState();
}

class _MyRidesState extends State<MyRides> {
  List<Ride> filteredRides = [];
  Map<String, dynamic>? userData;
  Future<void> fetchUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .get();
        if (docSnapshot.exists) {
          setState(() {
            userData = docSnapshot.data();
          });
          fetchAndFilterRides(userData: userData!);
        }
      }
    } catch (e) {
      logger.e('Error fetching user\'s data: $e');
    }
  }

  Future<void> fetchAndFilterRides({
    required Map<String, dynamic> userData,
  }) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('Cars').get();

      final allRides =
          querySnapshot.docs.map((doc) {
            return Ride.fromFirestore(data: doc.data());
          }).toList();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final filtered =
          allRides.where((ride) {
            final tourStartDate = ride.startDate.toDate();
            final userTourEndDate = userData['Tour End Date'];
            return ride.vehicleType == userData['Vehicle type'] &&
                ride.numOfGuests <= userData['Seat Number'] &&
                tourStartDate.isAfter(userTourEndDate.toDate()) &&
                ride.driver == userId;
          }).toList();

      setState(() {
        filteredRides = filtered;
      });
    } catch (e) {
      logger.e('Error fetching rides data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return filteredRides.isNotEmpty
        ? SizedBox(
          width: width,
          height: height,
          child: ListView.builder(
            itemCount: filteredRides.length,
            itemBuilder:
                (context, index) => _buildRide(
                  context: context,
                  darkMode: darkMode,
                  height: height,
                  width: width,
                  ride: filteredRides[index],
                ),
          ),
        )
        : Center(
          child: Text(
            'You don\'t have any Rides. Navigate to Rides page and grab some',
          ),
        );
  }

  Widget _buildRide({
    required BuildContext context,
    required Ride ride,
    required double height,
    required double width,
    required bool darkMode,
  }) {
    final tourStartDate = DateFormat(
      'dd MMMM yyyy, HH:mm',
    ).format(ride.startDate.toDate());

    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => DetailsPage(ride: ride)),
          ),

      child: Container(
        padding: EdgeInsets.all(width * 0.033),
        width: width,
        decoration: BoxDecoration(
          color: darkMode ? Colors.black54 : Colors.white38,
          borderRadius: BorderRadius.circular(width * 0.012),
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
                  ),
                ),
                SizedBox(height: height * 0.005),
                RichText(
                  text: TextSpan(
                    text: 'Start Date: ',
                    style: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: tourStartDate,
                        style: GoogleFonts.ptSans(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios_outlined),
          ],
        ),
      ),
    );
  }
}
