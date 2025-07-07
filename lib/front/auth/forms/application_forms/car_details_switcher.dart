import 'dart:convert';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/upload_files/vehicle_details/vehicle_details_provider.dart';
import 'package:onemoretour/front/displayed_items/intermediate_page_for_forms.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/upload_files/vehicle_details/upload_vehicle_details_save.dart';
import 'package:onemoretour/db/user_data/vehicle_type_provider.dart';
import 'package:onemoretour/front/auth/forms/application_forms/car_details_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// Handles switching between multiple car details forms based on the selected vehicle type.
// Allows users to input and upload details for one or multiple vehicles, including photos and metadata.


/// Widget responsible for displaying either a single car details form or a list of vehicles
/// the user must fill out, depending on how many vehicle types the user has selected.
class CarDetailsSwitcher extends ConsumerStatefulWidget {
  const CarDetailsSwitcher({super.key});

  @override
  ConsumerState<CarDetailsSwitcher> createState() => _CarDetailsSwitcherState();
}

class _CarDetailsSwitcherState extends ConsumerState<CarDetailsSwitcher> {
  final Map<String, GlobalKey<CarDetailsFormState>> formKeys = {};
  bool _formKeysInitialized = false;
  bool personalDecline = false;
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
    preloadVehicleDataIfNeeded();
  }

  /// Loads previously saved vehicle details from Firestore if the user had declined the form earlier.
  /// This helps prepopulate the form with existing data.
  Future<void> preloadVehicleDataIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
    final userData = userDoc.data();

    if (userData == null) return;

    final vehicleTypeField = userData['Vehicle Type'] ?? '';
    personalDecline = userData['Personal & Car Details Decline'] ?? false;

    if (!personalDecline) return;

    final List<dynamic> vehicleTypes =
        vehicleTypeField.split(',').map((e) => e.trim()).toList();

    final vehiclesSnapshot =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('Vehicles')
            .get();

    final newState = <String, dynamic>{};

    for (final doc in vehiclesSnapshot.docs) {
      final data = doc.data();
      final type = data['Vehicle\'s Type'] ?? '';
      final regNumber = data['Vehicle Registration Number'] ?? '';

      if (vehicleTypes.contains(type)) {
        final key = '$type - $regNumber';
        newState[key] = {
          'Vehicle Name': data['Vehicle Name'],
          'Vehicle Photos': data['Vehicle Photos'] ?? [],
          'Vehicle Photos Local': List<String>.from(
            data['Vehicle Photos'] ?? [],
          ),
          'Technical Passport Number': data['Technical Passport Number'],
          'Technical Passport Photos': data['Technical Passport Photos'] ?? [],
          'Technical Passport Photos Local': List<String>.from(
            data['Technical Passport Photos'] ?? [],
          ),
          'Chassis Number': data['Chassis Number'],
          'Chassis Number Photo': data['Chassis Number Photo'],
          'Chassis Number Photo Local': data['Chassis Number Photo'],
          'Vehicle Registration Number': regNumber,
          'Vehicle\'s Year': data['Vehicle\'s Year'],
          'Vehicle\'s Type': type,
          'Seat Number': data['Seat Number'],
          'isApproved': data['isApproved'] ?? false,
        };
      }
    }

    ref.read(vehicleDetailsProvider.notifier).state = newState;
  }

  Future<void> deletePhotoFromStorage(String photoUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(photoUrl);
      await ref.delete();
      logger.i('Photo deleted: $photoUrl');
    } catch (e) {
      logger.e('Error deleting photo: $e');
    }
  }

  /// Updates the Firestore document of the car with the given registration number using the provided form data.
  Future<void> updateCarIndexDoc({
    required String userId,
    required String regNumber,
    required Map<String, dynamic> formData,
  }) async {
    final vehiclesSnapshot =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('Vehicles')
            .get();

    for (final doc in vehiclesSnapshot.docs) {
      final data = doc.data();
      final existingRegNumber = data['Vehicle Registration Number'] ?? '';
      if (existingRegNumber == regNumber) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('Vehicles')
            .doc(doc.id)
            .update(formData);

        logger.i('Updated Vehicles/${doc.id} with new data for $regNumber');
        break;
      }
    }
  }

  /// Checks whether all required fields for a specific vehicle type are filled out.
  /// Returns true if valid, false otherwise.
  bool isVehicleFullyFilled(String type) {
    final detailsEntry = ref
        .read(vehicleDetailsProvider)
        .entries
        .firstWhere(
          (entry) => entry.key.startsWith('$type - '),
          orElse: () => MapEntry('', null),
        );

    final details = detailsEntry.value;
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
        if (!_formKeysInitialized) {
          final vehicleDetails = ref.read(vehicleDetailsProvider);
          for (final type in types) {
            String? regNumber;
            vehicleDetails.forEach((key, value) {
              if (key.startsWith('$type - ')) {
                regNumber = value['Vehicle Registration Number'];
              }
            });
            final keyName = '$type - ${regNumber ?? 'NEW'}';
            formKeys.putIfAbsent(
              keyName,
              () => GlobalKey<CarDetailsFormState>(),
            );
          }
          _formKeysInitialized = true;
        }
        if (types.length == 1) {
          String? regNumber;
          vehicleDetails.forEach((k, v) {
            if (k.startsWith('${types[0]} - ')) {
              regNumber = v['Vehicle Registration Number'];
            }
          });
          final keyName =
              regNumber != null ? '${types[0]} - $regNumber' : types[0];
          final formKey = formKeys[keyName];
          return CarDetailsForm(
            key: formKey,
            vehicleType: types[0],
            onDeleteRemotePhoto: (url) async {
              await deletePhotoFromStorage(url);
            },
            initialData: vehicleDetails[keyName],
            isDeclined: personalDecline,
            onFormSubmit: (formData) async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              final userId = user.uid;

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

                          List<String> carPhotoPaths = List<String>.from(
                            formData['Vehicle Photos Local'],
                          );
                          List<String> techPhotoPaths = List<String>.from(
                            formData['Technical Passport Photos Local'],
                          );
                          String chassisPhotoPath =
                              formData['Chassis Number Photo Local'];

                          List<String> uploadedCarPhotos =
                              await uploadMultiplePhotosFromPaths(
                                carPhotoPaths,
                                storageRef,
                                userId,
                                'Vehicle Photos',
                                formData['Vehicle Registration Number'],
                              );
                          List<String> uploadedTechPhotos =
                              await uploadMultiplePhotosFromPaths(
                                techPhotoPaths,
                                storageRef,
                                userId,
                                'Technical Passport',
                                formData['Vehicle Registration Number'],
                              );
                          String uploadedChassisPhoto =
                              await uploadSinglePhotoFromPath(
                                chassisPhotoPath,
                                storageRef,
                                userId,
                                'Chassis Number',
                                formData['Vehicle Registration Number'],
                              );

                          final finalFormData = {
                            ...formData,
                            'Vehicle Photos': uploadedCarPhotos,
                            'Technical Passport Photos': uploadedTechPhotos,
                            'Chassis Number Photo': uploadedChassisPhoto,
                            'isApproved': false,
                          };

                          if (context.mounted) {
                            await uploadVehicleDetailsAndSave(
                              userId: userId,
                              vehicleDetails: finalFormData,
                              context: context,
                            );
                          }

                          await FirebaseFirestore.instance
                              .collection('Users')
                              .doc(userId)
                              .update({
                                'Personal & Car Details Form':
                                    'APPLICATION RECEIVED',
                                'Active Vehicle': 'Car1',
                                'Personal & Car Details Decline': false,
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
            multiSelection: false,
          );
        } else {
          // Helper function to validate whether all vehicles listed have complete details before submission.
          bool allFormsProperlyFilledOut() {
            final vehicleDetails = ref.read(vehicleDetailsProvider);
            final types = ref.read(vehicleTypeProvider).asData?.value ?? [];

            for (final type in types) {
              final detailsEntry = vehicleDetails.entries.where(
                (entry) => entry.key.startsWith('$type - '),
              );

              for (final entry in detailsEntry) {
                final details = entry.value;

                if (details == null ||
                    details['Vehicle Name'] == null ||
                    details['Vehicle Name'].toString().isEmpty ||
                    details['Vehicle Photos Local'] == null ||
                    (details['Vehicle Photos Local'] as List).isEmpty ||
                    details['Technical Passport Number'] == null ||
                    details['Technical Passport Number'].toString().isEmpty ||
                    details['Technical Passport Photos Local'] == null ||
                    (details['Technical Passport Photos Local'] as List)
                        .isEmpty ||
                    details['Chassis Number'] == null ||
                    details['Chassis Number'].toString().isEmpty ||
                    details['Chassis Number Photo Local'] == null ||
                    details['Chassis Number Photo Local'].toString().isEmpty ||
                    details['Vehicle Registration Number'] == null ||
                    details['Vehicle Registration Number'].toString().isEmpty ||
                    details['Vehicle\'s Year'] == null ||
                    details['Vehicle\'s Year'].toString().isEmpty ||
                    details['Vehicle\'s Type'] == null ||
                    details['Seat Number'] == null) {
                  return false;
                }
              }
            }
            return true;
          }

          return PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: darkMode ? Colors.black : Colors.white,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: darkMode ? Colors.black : Colors.white,
                surfaceTintColor: darkMode ? Colors.black : Colors.white,

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
                  String? regNumber;
                  vehicleDetails.forEach((k, v) {
                    if (k.startsWith('${types[index]} - ')) {
                      regNumber = v['Vehicle Registration Number'];
                    }
                  });
                  final displayText =
                      regNumber != null && regNumber != 'NEW'
                          ? '${types[index]} - $regNumber'
                          : types[index];
                  // Displays a tile for each vehicle type, indicating completion status and opening its form on tap.
                  return ListTile(
                    title: Container(
                      width: width,
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
                        spacing: width * 0.03,
                        children: [
                          Image.asset(
                            vehicleTypeIcons[types[index]]!,
                            color: darkMode ? Colors.white : Colors.black,
                            width: width * 0.15,
                            height: height * 0.08,
                            fit: BoxFit.fill,
                          ),
                          Expanded(
                            flex: 20,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                softWrap: false,
                                maxLines: 1,
                                displayText,
                                style: GoogleFonts.cabin(
                                  fontSize: width * 0.05,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
                      String? regNumber;
                      vehicleDetails.forEach((k, v) {
                        if (k.startsWith('${types[index]} - ')) {
                          regNumber = v['Vehicle Registration Number'];
                        }
                      });
                      final keyName =
                          regNumber != null
                              ? '${types[index]} - $regNumber'
                              : types[index];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CarDetailsForm(
                                multiSelection: true,
                                key: formKeys[keyName],
                                onDeleteRemotePhoto: (url) async {
                                  await deletePhotoFromStorage(url);
                                },
                                vehicleType: types[index],
                                isDeclined: personalDecline,
                                initialData: vehicleDetails[keyName],
                                onFormSubmit: (formData) async {
                                  ref.read(vehicleDetailsProvider.notifier).update((
                                    state,
                                  ) {
                                    final updated = Map<String, dynamic>.from(
                                      state,
                                    );
                                    final newKey =
                                        '${formData['Vehicle\'s Type']} - ${formData['Vehicle Registration Number']}';
                                    updated[newKey] = formData;
                                    return updated;
                                  });
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
              // Handles final submission process for one or more vehicles, including uploading images and Firestore update.
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
                                  'Vehicle Photos Local':
                                      form['Vehicle Photos Local'],
                                  'Technical Passport Number':
                                      form['Technical Passport Number'],
                                  'Technical Passport Photos':
                                      uploadedTechPhotos,
                                  'Technical Passport Photos Local':
                                      form['Technical Passport Photos Local'],
                                  'Chassis Number': form['Chassis Number'],
                                  'Chassis Number Photo': uploadedChassisPhoto,
                                  'Chassis Number Photo Local':
                                      form['Chassis Number Photo Local'],
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
                                    'Personal & Car Details Decline': false,
                                  });

                              final prefs =
                                  await SharedPreferences.getInstance();
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
                        allFormsProperlyFilledOut()
                            ? (darkMode
                                ? Color.fromARGB(255, 1, 105, 170)
                                : Color.fromARGB(255, 0, 134, 179))
                            : (darkMode
                                ? Color.fromARGB(40, 52, 168, 235)
                                : Color.fromARGB(40, 0, 134, 179)),
                    borderRadius: BorderRadius.circular(7.5),
                  ),
                  child: Center(
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: width * 0.04,
                        color:
                            allFormsProperlyFilledOut()
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
