import 'dart:convert';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/upload_files/vehicle_details/vehicle_details_provider.dart';
import 'package:driver_app/front/displayed_items/intermediate_page_for_forms.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/upload_files/vehicle_details/upload_vehicle_details_save.dart';
import 'package:driver_app/db/user_data/vehicle_type_provider.dart';
import 'package:driver_app/front/auth/forms/application_forms/car_details_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class CarDetailsSwitcher extends ConsumerStatefulWidget {
  const CarDetailsSwitcher({super.key});

  @override
  ConsumerState<CarDetailsSwitcher> createState() => _CarDetailsSwitcherState();
}

class _CarDetailsSwitcherState extends ConsumerState<CarDetailsSwitcher> {
  late Map<String, GlobalKey<CarDetailsFormState>> formKeys;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final stored = prefs.getString('vehicleDetails');
      if (stored != null && stored.isNotEmpty) {
        ref
            .read(vehicleDetailsProvider.notifier)
            .state = Map<String, dynamic>.from(jsonDecode(stored));
      }
    });
  }

  bool isVehicleFullyFilled(String vehicleType) {
    final details = ref.read(vehicleDetailsProvider)[vehicleType];
    if (details == null) return false;

    return details['Vehicle Name'] != null &&
        details['Vehicle Name'].toString().isNotEmpty &&
        details['Vehicle Photos Local'] != null &&
        (details['Vehicle Photos Local'] as List).isNotEmpty &&
        details['Technical Passport Number'] != null &&
        details['Technical Passport Number'].toString().isNotEmpty &&
        details['Technical Passport Photos Local'] != null &&
        (details['Technical Passport Photos Local'] as List).isNotEmpty &&
        details['Chassis Number'] != null &&
        details['Chassis Number'].toString().isNotEmpty &&
        details['Chassis Number Photo Local'] != null &&
        details['Chassis Number Photo Local'].toString().isNotEmpty &&
        details['Vehicle Registration Number'] != null &&
        details['Vehicle Registration Number'].toString().isNotEmpty &&
        details['Vehicle\'s Year'] != null &&
        details['Vehicle\'s Year'].toString().isNotEmpty &&
        details['Vehicle\'s Type'] != null &&
        details['Seat Number'] != null;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleTypes = ref.watch(vehicleTypeProvider);
    final vehicleDetails = ref.watch(vehicleDetailsProvider);
    ref.listen<Map<String, dynamic>>(vehicleDetailsProvider, (
      previous,
      next,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vehicleDetails', jsonEncode(next));
    });
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final Map<String, String> vehicleTypeIcons = {
      'Sedan': "assets/car_icons/sedan.png",
      'Minivan': "assets/car_icons/mininvan.png",
      'SUV': "assets/car_icons/SUV.png",
      'Premium SUV': "assets/car_icons/premium_SUV.png",
      'Bus': "assets/car_icons/bus.png",
    };
    return vehicleTypes.maybeWhen(
      data: (types) {
        formKeys = {
          for (final type in types) type: GlobalKey<CarDetailsFormState>(),
        };
        if (types.length == 1) {
          final formKey = formKeys[types[0]]!;
          return CarDetailsForm(
            multiSelection: false,
            key: formKey,
            onFormSubmit: (formData) async {
              if (context.mounted) {
                await Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: IntermediateFormPage(
                      isFromPersonalDataForm: false,
                      isFromBankDetailsForm: false,
                      isFromCertificateDetailsForm: false,
                      isFromCarDetailsSwitcher: false,
                      isFromCarDetailsForm: true,
                      isFromProfilePage: false,
                      backgroundProcess: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        final userId = user.uid;
                        if (context.mounted) {
                          final form =
                              ref.read(vehicleDetailsProvider)[types[0]];

                          if (form != null) {
                            final carPhotoPaths = List<String>.from(
                              form['Vehicle Photos Local'],
                            );
                            final techPhotoPaths = List<String>.from(
                              form['Technical Passport Photos Local'],
                            );
                            final chassisPhotoPath =
                                form['Chassis Number Photo Local'];

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
                                  form['Vehicle Registration Number'],
                                );

                            final uploadedTechPhotos =
                                await uploadMultiplePhotosFromPaths(
                                  techPhotoPaths,
                                  storageRef,
                                  userId,
                                  'Technical Passport',
                                  form['Vehicle Registration Number'],
                                );

                            final uploadedChassisPhoto =
                                await uploadSinglePhotoFromPath(
                                  chassisPhotoPath,
                                  storageRef,
                                  userId,
                                  'Chassis Number',
                                  form['Vehicle Registration Number'],
                                );

                            final finalFormData = {
                              'Vehicle Name': form['Vehicle Name'],
                              'Vehicle Photos': uploadedCarPhotos,
                              'Technical Passport Number':
                                  form['Technical Passport Number'],
                              'Technical Passport Photos': uploadedTechPhotos,
                              'Chassis Number': form['Chassis Number'],
                              'Chassis Number Photo': uploadedChassisPhoto,
                              'Vehicle Registration Number':
                                  form['Vehicle Registration Number'],
                              'Vehicle\'s Year': form['Vehicle\'s Year'],
                              'Vehicle\'s Type': form['Vehicle\'s Type'],
                              'Seat Number': form['Seat Number'],
                              'isApproved': false,
                            };

                            if (context.mounted) {
                              await uploadVehicleDetailsAndSave(
                                userId: userId,
                                vehicleDetails: finalFormData,
                                context: context,
                              );
                            }
                          }
                        }
                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(userId)
                            .update({
                              'Personal & Car Details Form':
                                  'APPLICATION RECEIVED',
                              'Active Vehicle': "Car1",
                            });
                      },
                    ),
                  ),
                );
              }
            },
            vehicleType: types[0],
          );
        } else {
          bool allFilledOut() {
            for (var type in types) {
              if (!vehicleDetails.containsKey(type)) {
                return false;
              }
            }
            return true;
          }

          bool allFormsProperlyFilledOut() {
            ref.read(vehicleDetailsProvider);
            final types = ref.read(vehicleTypeProvider).asData?.value ?? [];

            for (final type in types) {
              if (!isVehicleFullyFilled(type)) return false;
            }
            return true;
          }

          return Scaffold(
            backgroundColor: darkMode ? Colors.black : Colors.white,
            appBar: AppBar(
              backgroundColor: darkMode ? Colors.black : Colors.white,
              surfaceTintColor: darkMode ? Colors.black : Colors.white,
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
              title: Text(
                'Share the details to all your vehicles',
                softWrap: true,
                maxLines: 2,
                style: TextStyle(
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.w700,
                  color: darkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            body: ListView.builder(
              itemCount: types.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: height * 0.0005,
                      horizontal: width * 0.03,
                    ),
                    decoration: BoxDecoration(
                      color: darkMode ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            darkMode
                                ? const Color.fromARGB(255, 52, 168, 235)
                                : const Color.fromARGB(255, 0, 134, 179),
                      ),
                    ),
                    child: Row(
                      spacing: width * 0.05,
                      children: [
                        Image.asset(
                          vehicleTypeIcons[types[index]]!,
                          color: darkMode ? Colors.white : Colors.black,
                          width: width * 0.15,
                          height: height * 0.08,
                          fit: BoxFit.fill,
                        ),
                        SizedBox(width: width * 0.05),
                        Text(
                          types[index],
                          style: GoogleFonts.cabin(
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Spacer(),
                        isVehicleFullyFilled(types[index])
                            ? Icon(
                              Icons.check_box_rounded,
                              color:
                                  darkMode
                                      ? Color(0xFF34A8EB)
                                      : Color(0xFF0086B3),
                              size: width * 0.07,
                            )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CarDetailsForm(
                              multiSelection: true,
                              key: formKeys[types[index]],
                              onFormSubmit: (formData) async {
                                ref
                                    .read(vehicleDetailsProvider.notifier)
                                    .update((state) {
                                      final updated = Map<String, dynamic>.from(
                                        state,
                                      );
                                      updated[types[index]] = formData;

                                      return updated;
                                    });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              vehicleType: types[index],
                            ),
                      ),
                    );
                  },
                );
              },
            ),
            floatingActionButton: GestureDetector(
              onTap: () async {
                if (!allFormsProperlyFilledOut()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please fill out all vehicle details before submitting.',
                      ),
                    ),
                  );
                  return;
                }
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                final userId = user.uid;
                final vehicleDetails = ref.read(vehicleDetailsProvider);
                if (context.mounted) {
                  await Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.fade,
                      child: IntermediateFormPage(
                        isFromPersonalDataForm: false,
                        isFromCarDetailsForm: false,
                        isFromBankDetailsForm: false,
                        isFromCertificateDetailsForm: false,
                        isFromCarDetailsSwitcher: true,
                        isFromProfilePage: false,
                        backgroundProcess: () async {
                          try {
                            final storageRef = FirebaseStorage.instance
                                .ref()
                                .child('Users')
                                .child(userId);

                            for (final entry in vehicleDetails.entries) {
                              final form = entry.value;

                              List<String> carPhotoPaths = List<String>.from(
                                form['Vehicle Photos Local'],
                              );
                              List<String> techPhotoPaths = List<String>.from(
                                form['Technical Passport Photos Local'],
                              );
                              String chassisPhotoPath =
                                  form['Chassis Number Photo Local'];

                              List<String> uploadedCarPhotos =
                                  await uploadMultiplePhotosFromPaths(
                                    carPhotoPaths,
                                    storageRef,
                                    userId,
                                    'Vehicle Photos',
                                    form['Vehicle Registration Number'],
                                  );
                              List<String> uploadedTechPhotos =
                                  await uploadMultiplePhotosFromPaths(
                                    techPhotoPaths,
                                    storageRef,
                                    userId,
                                    'Technical Passport',
                                    form['Vehicle Registration Number'],
                                  );
                              String uploadedChassisPhoto =
                                  await uploadSinglePhotoFromPath(
                                    chassisPhotoPath,
                                    storageRef,
                                    userId,
                                    'Chassis Number',
                                    form['Vehicle Registration Number'],
                                  );

                              final finalFormData = {
                                'Vehicle Name': form['Vehicle Name'],
                                'Vehicle Photos': uploadedCarPhotos,
                                'Technical Passport Number':
                                    form['Technical Passport Number'],
                                'Technical Passport Photos': uploadedTechPhotos,
                                'Chassis Number': form['Chassis Number'],
                                'Chassis Number Photo': uploadedChassisPhoto,
                                'Vehicle Registration Number':
                                    form['Vehicle Registration Number'],
                                'Vehicle\'s Year': form['Vehicle\'s Year'],
                                'Vehicle\'s Type': form['Vehicle\'s Type'],
                                'Seat Number': form['Seat Number'],
                                'isApproved': false,
                              };
                              if (context.mounted) {
                                await uploadVehicleDetailsAndSave(
                                  userId: userId,
                                  vehicleDetails: finalFormData,
                                  context: context,
                                );
                              }
                            }
                            await FirebaseFirestore.instance
                                .collection('Users')
                                .doc(userId)
                                .update({
                                  'Personal & Car Details Form':
                                      'APPLICATION RECEIVED',
                                  'Active Vehicle': "Car1",
                                });

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('vehicleDetails');
                          } catch (e) {
                            logger.e('Error uploading vehicle details: $e');
                          }
                        },
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: width * 0.93,
                height: height * 0.058,
                decoration: BoxDecoration(
                  color:
                      allFilledOut()
                          ? (darkMode
                              ? Color.fromARGB(255, 1, 105, 170)
                              : Color.fromARGB(255, 0, 134, 179))
                          : (darkMode
                              ? Color.fromARGB(128, 52, 168, 235)
                              : Color.fromARGB(177, 0, 134, 179)),
                  borderRadius: BorderRadius.circular(7.5),
                ),
                child: Center(
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: width * 0.04,
                      color:
                          allFilledOut()
                              ? (darkMode
                                  ? Color.fromARGB(255, 0, 0, 0)
                                  : Color.fromARGB(255, 255, 255, 255))
                              : (darkMode
                                  ? Color.fromARGB(132, 0, 0, 0)
                                  : Color.fromARGB(187, 255, 255, 255)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
