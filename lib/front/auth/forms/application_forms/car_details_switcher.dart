import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/tools/loading_notifier.dart';
import 'package:driver_app/back/upload_files/vehicle_details/upload_vehicle_details_save.dart';
import 'package:driver_app/db/user_data/vehicle_type_provider.dart';
import 'package:driver_app/front/auth/forms/application_forms/car_details_form.dart';
import 'package:driver_app/front/auth/waiting_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class CarDetailsSwitcher extends ConsumerWidget {
  const CarDetailsSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleTypes = ref.watch(vehicleTypeProvider);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    Map<String, dynamic> vehicleDetails = {};

    final Map<String, String> vehicleTypeIcons = {
      'Sedan': "assets/car_icons/sedan.png",
      'Minivan': "assets/car_icons/mininvan.png",
      'SUV': "assets/car_icons/SUV.png",
      'Premium SUV': "assets/car_icons/premium_SUV.png",
      'Bus': "assets/car_icons/bus.png",
    };
    return vehicleTypes.maybeWhen(
      data: (types) {
        if (types.length == 1) {
          return CarDetailsForm(
            onFormSubmit: (formData) async {
              vehicleDetails[types[0]] = formData;
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                await uploadVehicleDetailsAndSave(
                  userId: userId,
                  vehicleDetails: vehicleDetails,
                  context: context,
                );
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .update({
                      'Personal & Car Details Form': 'APPLICATION RECEIVED',
                    });

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WaitingPage(),
                    ),
                    (route) => false,
                  );
                }
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

          final isLoading = ref.watch(loadingProvider);
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
                        Text(
                          types[index],
                          style: GoogleFonts.cabin(
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Spacer(),
                        vehicleDetails.containsKey(types[index])
                            ? Icon(
                              Icons.check_box_rounded,
                              color:
                                  darkMode
                                      ? const Color.fromARGB(255, 52, 168, 235)
                                      : const Color.fromARGB(255, 0, 134, 179),
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
                              onFormSubmit: (formData) {
                                vehicleDetails[types[index]] = formData;
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
                if (allFilledOut()) {
                  ref.read(loadingProvider.notifier).startLoading();
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId != null) {
                    await uploadVehicleDetailsAndSave(
                      userId: userId,
                      vehicleDetails: vehicleDetails,
                      context: context,
                    );
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userId)
                        .update({
                          'Personal & Car Details Form': 'APPLICATION RECEIVED',
                        });

                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WaitingPage(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                  ref.read(loadingProvider.notifier).stopLoading();
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
                child:
                    isLoading
                        ? Center(
                          child: SpinKitThreeBounce(
                            color: Color.fromRGBO(231, 231, 231, 1),
                            size: width * 0.061,
                          ),
                        )
                        : Center(
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
