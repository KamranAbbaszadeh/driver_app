import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/upload_files/vehicle_details/upload_vehicle_details_save.dart';
import 'package:driver_app/front/auth/forms/application_forms/car_details_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListState();
}

class _VehicleListState extends State<VehicleList> {
  final Map<String, String> vehicleTypeIcons = {
    'Sedan': "assets/car_icons/sedan.png",
    'Minivan': "assets/car_icons/mininvan.png",
    'SUV': "assets/car_icons/SUV.png",
    'Premium SUV': "assets/car_icons/premium_SUV.png",
    'Bus': "assets/car_icons/bus.png",
  };

  String? activeVehicleId;

  Future<List<Map<String, dynamic>>> fetchVehiclesWithSelection() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];
    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    activeVehicleId = userDoc.data()?['Active Vehicle'];

    final snapshot =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('Vehicles')
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {...data, 'docId': doc.id};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vehicle List',
          style: GoogleFonts.ptSans(
            fontSize: width * 0.066,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      ),
      body: Container(
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchVehiclesWithSelection(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No vehicles found.'));
            }

            final vehicles = snapshot.data!;
            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isSelected = vehicle['docId'] == activeVehicleId;
                final isApproved = vehicle['isApproved'] == true;
                final seatNumber = vehicle['Seat Number']?.toString() ?? '-';
                final vehicleYear =
                    vehicle['Vehicle\'s Year']?.toString() ?? '-';
                return Card(
                  margin: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.009,
                  ),
                  elevation: width * 0.005,
                  color:
                      isApproved
                          ? Theme.of(context).cardColor
                          : Colors.grey[300],
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.03),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              vehicleTypeIcons[vehicle['vehicleType']] ??
                                  'assets/car_icons/sedan.png',
                              width: width * 0.1,
                              height: width * 0.1,
                              color: darkMode ? Colors.white : Colors.black,
                            ),
                            SizedBox(width: width * 0.04),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle['Vehicle Registration Number'] ??
                                      'Unknown',
                                  style: GoogleFonts.ptSans(
                                    fontSize: width * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: height * 0.004),
                                RichText(
                                  text: TextSpan(
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    children: [
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
                              ],
                            ),
                          ],
                        ),
                        if (isSelected)
                          Container(
                            width: width * 0.035,
                            height: height * 0.021,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 103, 168, 120),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            darkMode
                ? Color.fromARGB(255, 1, 105, 170)
                : Color.fromARGB(255, 52, 168, 235),
        foregroundColor: darkMode ? Colors.white : Colors.black,

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CarDetailsForm(
                    multiSelection: false,
                    vehicleType: '',
                    onFormSubmit: (formData) async {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      final selectedVehicleType = formData['Vehicle\'s Type'];

                      if (userId != null && selectedVehicleType != null) {
                        final userRef = FirebaseFirestore.instance
                            .collection('Users')
                            .doc(userId);
                        final userDoc = await userRef.get();
                        final currentTypes =
                            userDoc.data()?['Vehicle type'] ?? '';

                        final updatedTypes =
                            currentTypes.isEmpty
                                ? selectedVehicleType
                                : '$currentTypes, $selectedVehicleType';

                        await userRef.update({'Vehicle type': updatedTypes});

                        if (context.mounted) {
                          await uploadVehicleDetailsAndSave(
                            userId: userId,
                            vehicleDetails: {selectedVehicleType: formData},
                            context: context,
                          );
                        }

                        if (context.mounted) Navigator.pop(context);
                        setState(() {});
                      }
                    },
                  ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
