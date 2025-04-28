import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/upload_files/vehicle_details/upload_vehicle_details_save.dart';
import 'package:driver_app/front/auth/forms/application_forms/car_details_form.dart';
import 'package:driver_app/front/displayed_items/intermediate_page_for_forms.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

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

  @override
  void initState() {
    super.initState();
    fetchActiveVehicleId();
  }

  Future<void> fetchActiveVehicleId() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    setState(() {
      activeVehicleId = userDoc.data()?['Active Vehicle'];
    });
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
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('Users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('Vehicles')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No vehicles found.'));
            }

            final vehicles =
                snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {...data, 'docId': doc.id};
                }).toList();

            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isSelected = vehicle['docId'] == activeVehicleId;
                final isApproved = vehicle['isApproved'] == true;
                final seatNumber = vehicle['Seat Number']?.toString() ?? '-';
                final vehicleYear =
                    vehicle['Vehicle\'s Year']?.toString() ?? '-';
                return InkWell(
                  onTap:
                      isApproved && !isSelected
                          ? () async {
                            final userId =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (userId == null) return;

                            final selectedVehicleDocId = vehicle['docId'];

                            await FirebaseFirestore.instance
                                .collection('Users')
                                .doc(userId)
                                .update({
                                  'Active Vehicle': selectedVehicleDocId,
                                });

                            setState(() {
                              fetchActiveVehicleId();
                            });
                          }
                          : () {},
                  child: Card(
                    margin: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: height * 0.009,
                    ),
                    elevation: width * 0.025,
                    shadowColor: Colors.black.withAlpha((255 * 0.1).toInt()),
                    color:
                        isApproved
                            ? (darkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.white)
                            : (darkMode
                                ? const Color(0xFF424242)
                                : const Color.fromARGB(255, 167, 167, 167)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.05),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.03),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
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
                                  Text(
                                    vehicle['Vehicle Registration Number'] ??
                                        'Unknown',
                                    style: GoogleFonts.ptSans(
                                      fontSize: width * 0.04,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
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
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.02,
                                vertical: height * 0.004,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 103, 168, 120),
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
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: width * 0.025,
        backgroundColor: Colors.transparent,
        onPressed: () {
          final formKey = GlobalKey<CarDetailsFormState>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CarDetailsForm(
                    multiSelection: false,
                    vehicleType: '',
                    key: formKey,
                    onFormSubmit: (formData) async {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      final selectedVehicleType = formData['Vehicle\'s Type'];

                      if (userId != null &&
                          selectedVehicleType != null &&
                          context.mounted) {
                        await Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child: IntermediateFormPage(
                              isFromPersonalDataForm: false,
                              isFromBankDetailsForm: false,
                              isFromCertificateDetailsForm: false,
                              isFromCarDetailsSwitcher: false,
                              isFromCarDetailsForm: false,
                              isFromProfilePage: true,
                              backgroundProcess: () async {
                                final formData =
                                    await formKey.currentState
                                        ?.prepareVehicleFormData();
                                if (formData == null) return;

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

                                await userRef.update({
                                  'Vehicle type': updatedTypes,
                                });

                                if (context.mounted) {
                                  await uploadVehicleDetailsAndSave(
                                    userId: userId,
                                    vehicleDetails: {
                                      selectedVehicleType: formData,
                                    },
                                    context: context,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                        setState(() {});
                      }
                    },
                  ),
            ),
          );
        },
        child: Container(
          width: width * 0.142,
          height: height * 0.065,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors:
                  darkMode
                      ? [Color(0xFF34A8EB), Color(0xFF015E9C)]
                      : [Color(0xFF34A8EB), Color(0xFF015E9C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.add, size: width * 0.076, color: Colors.white),
        ),
      ),
    );
  }
}
