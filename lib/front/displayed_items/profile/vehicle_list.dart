import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/upload_files/vehicle_details/upload_vehicle_details_save.dart';
import 'package:onemoretour/front/auth/forms/application_forms/car_details_form.dart';
import 'package:onemoretour/front/displayed_items/intermediate_page_for_forms.dart';
import 'package:onemoretour/front/displayed_items/profile/vehicle_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

class VehicleList extends ConsumerStatefulWidget {
  const VehicleList({super.key});

  @override
  ConsumerState<VehicleList> createState() => _VehicleListState();
}

class _VehicleListState extends ConsumerState<VehicleList> {
  final Map<String, String> vehicleTypeIcons = {
    'Sedan': "assets/car_icons/sedan.png",
    'Minivan': "assets/car_icons/mininvan.png",
    'SUV': "assets/car_icons/SUV.png",
    'Premium SUV': "assets/car_icons/premium_SUV.png",
    'Bus': "assets/car_icons/bus.png",
  };

  final ValueNotifier<String?> activeVehicleIdNotifier = ValueNotifier(null);
  StreamSubscription<DocumentSnapshot>? activeVehicleSubscription;

  @override
  void initState() {
    super.initState();
    listenToActiveVehicleId();
  }

  void listenToActiveVehicleId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    activeVehicleSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          final data = snapshot.data();
          if (data != null && data.containsKey('Active Vehicle')) {
            activeVehicleIdNotifier.value = data['Active Vehicle'];
          }
        });
  }

  @override
  void dispose() {
    activeVehicleSubscription?.cancel();
    activeVehicleIdNotifier.dispose();
    super.dispose();
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
                final isApproved = vehicle['isApproved'] == true;

                return VehicleCard(
                  vehicle: vehicle,
                  isApproved: isApproved,
                  width: width,
                  height: height,
                  darkMode: darkMode,
                  vehicleTypeIcons: vehicleTypeIcons,
                  activeVehicleIdNotifier: activeVehicleIdNotifier,
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    final userId = user.uid;

                    final selectedVehicleDocId = vehicle['docId'];

                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userId)
                        .update({'Active Vehicle': selectedVehicleDocId});
                  },
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
                    isDeclined: false,
                    onDeleteRemotePhoto: (url) async {},
                    onFormSubmit: (formData) async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      final userId = user.uid;
                      final selectedVehicleType = formData['Vehicle\'s Type'];

                      if (selectedVehicleType != null && context.mounted) {
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
                                final carPhotoPaths = List<String>.from(
                                  formData['Vehicle Photos Local'],
                                );
                                final techPhotoPaths = List<String>.from(
                                  formData['Technical Passport Photos Local'],
                                );
                                final chassisPhotoPath =
                                    formData['Chassis Number Photo Local'];

                                final storageRef = FirebaseStorage.instance
                                    .ref()
                                    .child('Users')
                                    .child(userId);

                                final uploadedCarPhotos =
                                    await uploadMultiplePhotosFromPaths(
                                      carPhotoPaths,
                                      storageRef,
                                      userId,
                                      'Vehicle Photos',
                                      formData['Vehicle Registration Number'],
                                    );

                                final uploadedTechPhotos =
                                    await uploadMultiplePhotosFromPaths(
                                      techPhotoPaths,
                                      storageRef,
                                      userId,
                                      'Technical Passport',
                                      formData['Vehicle Registration Number'],
                                    );

                                final uploadedChassisPhoto =
                                    await uploadSinglePhotoFromPath(
                                      chassisPhotoPath,
                                      storageRef,
                                      userId,
                                      'Chassis Number',
                                      formData['Vehicle Registration Number'],
                                    );

                                final finalFormData = {
                                  'Vehicle Name': formData['Vehicle Name'],
                                  'Vehicle Photos': uploadedCarPhotos,
                                  'Technical Passport Number':
                                      formData['Technical Passport Number'],
                                  'Technical Passport Photos':
                                      uploadedTechPhotos,
                                  'Chassis Number': formData['Chassis Number'],
                                  'Chassis Number Photo': uploadedChassisPhoto,
                                  'Vehicle Registration Number':
                                      formData['Vehicle Registration Number'],
                                  'Vehicle\'s Year':
                                      formData['Vehicle\'s Year'],
                                  'Vehicle\'s Type':
                                      formData['Vehicle\'s Type'],
                                  'Seat Number': formData['Seat Number'],
                                  'isApproved': false,
                                };

                                if (context.mounted) {
                                  await uploadVehicleDetailsAndSave(
                                    userId: userId,
                                    vehicleDetails: finalFormData,
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
