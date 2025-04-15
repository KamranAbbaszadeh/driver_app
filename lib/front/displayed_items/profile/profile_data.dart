import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/rides_history/rides_provider.dart';
import 'package:driver_app/back/tools/image_picker.dart';
import 'package:driver_app/back/upload_files/vehicle_details/upload_vehicle_details_save.dart';
import 'package:driver_app/back/user/user_data_provider.dart';
import 'package:driver_app/front/displayed_items/profile/full_screen_image_viewer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProfileData extends ConsumerStatefulWidget {
  const ProfileData({super.key});

  @override
  ConsumerState<ProfileData> createState() => _ProfileDataState();
}

class _ProfileDataState extends ConsumerState<ProfileData> {
  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(currentUserDataProvider);
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final ridesHistoryNotifier = ref.watch(ridesHistoryProvider.notifier);
    dynamic profilePhoto;
    final completedCount = ridesHistoryNotifier.completedRidesCount;
    final nonCompletedCount = ridesHistoryNotifier.nonCompletedRidesCount;
    ref.watch(ridesHistoryProvider);
    final earnings = ridesHistoryNotifier.totalCompletedEarnings;

    return Scaffold(
      appBar: AppBar(
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
      body: userData.when(
        data: (user) {
          final formatted = DateFormat(
            'dd/M/yyyy HH:mm',
          ).format(user.lastTourEndDate);
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                spacing: width * 0.03,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: height * 0.001,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                backgroundColor: Colors.white,
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(width * 0.05),
                                  ),
                                ),
                                builder: (context) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(
                                            Icons.image,
                                            color:
                                                darkMode
                                                    ? Color.fromARGB(
                                                      255,
                                                      1,
                                                      105,
                                                      170,
                                                    )
                                                    : Color.fromARGB(
                                                      255,
                                                      52,
                                                      168,
                                                      235,
                                                    ),
                                          ),
                                          title: Text(
                                            'View Profile Photo',
                                            style: GoogleFonts.cabin(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                              fontSize: width * 0.04,
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      _,
                                                    ) => FullscreenImageViewer(
                                                      imageUrl:
                                                          user.personalPhoto!,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.camera_alt,
                                            color:
                                                darkMode
                                                    ? Color.fromARGB(
                                                      255,
                                                      1,
                                                      105,
                                                      170,
                                                    )
                                                    : Color.fromARGB(
                                                      255,
                                                      52,
                                                      168,
                                                      235,
                                                    ),
                                          ),
                                          title: Text(
                                            'Change Profile Photo',
                                            style: GoogleFonts.cabin(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                              fontSize: width * 0.04,
                                            ),
                                          ),
                                          onTap: () async {
                                            try {
                                              Navigator.pop(context);

                                              final storageRef =
                                                  FirebaseStorage.instance
                                                      .ref();
                                              final firestore =
                                                  FirebaseFirestore.instance;

                                              final selected =
                                                  await ImagePickerHelper.selectSinglePhoto(
                                                    context: context,
                                                  );
                                              if (selected == null) return;

                                              setState(
                                                () => profilePhoto = selected,
                                              );
                                              if (user.personalPhoto != null &&
                                                  user
                                                      .personalPhoto!
                                                      .isNotEmpty) {
                                                final previousRef =
                                                    FirebaseStorage.instance
                                                        .refFromURL(
                                                          user.personalPhoto!,
                                                        );
                                                await previousRef.delete();
                                              }

                                              try {
                                                final newImage =
                                                    await uploadSinglePhoto(
                                                      storageRef: storageRef,
                                                      userID: user.userId,
                                                      file: profilePhoto,
                                                      folderName:
                                                          'personalPhoto',
                                                    );

                                                await firestore
                                                    .collection('Users')
                                                    .doc(user.userId)
                                                    .set({
                                                      'personalPhoto': newImage,
                                                    }, SetOptions(merge: true));
                                              } on Exception catch (e) {
                                                logger.e(e);
                                              }
                                            } catch (e) {
                                              logger.e(e);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: SizedBox(
                              width: width * 0.4,
                              height: height * 0.18,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  width * 0.3,
                                ),
                                child:
                                    (user.personalPhoto != null &&
                                            user.personalPhoto!.isNotEmpty)
                                        ? CachedNetworkImage(
                                          imageUrl: user.personalPhoto!,
                                          placeholder:
                                              (context, url) =>
                                                  CircularProgressIndicator(),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Icon(Icons.error),
                                          fit: BoxFit.cover,
                                        )
                                        : Icon(Icons.person, size: width * 0.3),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Text(
                            '${user.firstName} ${user.lastName}',
                            style: GoogleFonts.cabin(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.06,
                            ),
                          ),
                          Text(
                            user.role,
                            style: GoogleFonts.cabin(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.04,
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: width * 0.05,
                            children: [
                              Column(
                                spacing: height * 0.01,
                                children: [
                                  Text(
                                    "Total Rides",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color: const Color.fromARGB(
                                        255,
                                        32,
                                        35,
                                        119,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    nonCompletedCount.toString(),
                                    style: GoogleFonts.alfaSlabOne(
                                      fontWeight: FontWeight.w400,
                                      fontSize: width * 0.035,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                spacing: height * 0.01,
                                children: [
                                  Text(
                                    'Completed Rires',
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color: const Color.fromARGB(
                                        255,
                                        32,
                                        35,
                                        119,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    completedCount.toString(),
                                    style: GoogleFonts.alfaSlabOne(
                                      fontWeight: FontWeight.w400,
                                      fontSize: width * 0.035,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                spacing: height * 0.01,
                                children: [
                                  Text(
                                    'Total Earnings',
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color: const Color.fromARGB(
                                        255,
                                        32,
                                        35,
                                        119,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    earnings.toString(),
                                    style: GoogleFonts.alfaSlabOne(
                                      fontWeight: FontWeight.w400,
                                      fontSize: width * 0.035,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(width * 0.019),
                        topRight: Radius.circular(width * 0.019),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.03),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        spacing: height * 0.01,
                        children: [
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.mail,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Email Address",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      user.email,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.phone_iphone,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Phone Number",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      user.phoneNumber,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.person,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Gender",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      user.gender,
                                      softWrap: true,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.date_range,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Date of Birth",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      user.birthday,
                                      softWrap: true,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.work,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Experience",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      user.experience,
                                      softWrap: true,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.home_filled,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Address",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      user.address ?? "",
                                      softWrap: true,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.label,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "FIN",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      user.fin,
                                      softWrap: true,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.time_to_leave,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Vehicle Type",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      user.vehicleType ?? "",
                                      softWrap: true,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.language,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Language Spoken",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      user.languageSpoken,
                                      softWrap: true,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            spacing: width * 0.06,
                            children: [
                              Icon(
                                Icons.access_time,
                                color:
                                    darkMode
                                        ? Color.fromARGB(255, 1, 105, 170)
                                        : Color.fromARGB(255, 52, 168, 235),
                                size: width * 0.07,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Last Tour End Date",
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.037,
                                      color:
                                          darkMode
                                              ? Color.fromARGB(255, 1, 105, 170)
                                              : Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      formatted.toString(),
                                      softWrap: true,
                                      style: GoogleFonts.cabin(
                                        fontWeight: FontWeight.normal,
                                        fontSize: width * 0.037,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}
