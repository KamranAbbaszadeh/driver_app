import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/tools/firebase_service.dart';
import 'package:driver_app/db/user_data/store_role.dart';
import 'package:driver_app/front/tools/notification_notifier.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildAppBar extends ConsumerStatefulWidget {
  const BuildAppBar({super.key});

  @override
  ConsumerState<BuildAppBar> createState() => _BuildAppBarState();
}

class _BuildAppBarState extends ConsumerState<BuildAppBar> {
  List<String> vehicleIds = [];
  List<Map<String, dynamic>> vehicles = [];
  final Map<String, String> vehicleTypeIcons = {
    'Sedan': "assets/car_icons/sedan.png",
    'Minivan': "assets/car_icons/mininvan.png",
    'SUV': "assets/car_icons/SUV.png",
    'Premium SUV': "assets/car_icons/premium_SUV.png",
    'Bus': "assets/car_icons/bus.png",
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.watch(notificationsProvider.notifier).refresh();
      fetchVehicleIds();
    });
  }

  Future<void> fetchVehicleIds() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('Vehicles')
            .get();

    setState(() {
      vehicles =
          snapshot.docs.where((doc) => doc.data()['isApproved'] == true).map((
            doc,
          ) {
            final data = doc.data();
            return {
              'id': doc.id,
              'registration': data['Vehicle Registration Number'] ?? doc.id,
              'vehicleType': data['Vehicle Type'] ?? 'Unknown',
            };
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final notifications = ref.watch(notificationsProvider);
    final hasUnviewedNotifications = notifications.any((notif) {
      return notif['isViewed'] == false;
    });
    final roleDetails = ref.watch(roleProvider);
    final userRole = roleDetails?['Role'];

    var userData = ref.watch(usersDataProvider);
    if (userData == null) {
      return CircularProgressIndicator();
    }

    String profilePicture = userData['personalPhoto'];
    String firstName = userData['First Name'];

    return AppBar(
      title: Row(
        children: [
          SizedBox(
            width: width * 0.114,
            height: height * 0.052,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.025),
              child: CachedNetworkImage(
                imageUrl: profilePicture,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: width * 0.025),
          Text(
            'Hi, $firstName!',
            style: GoogleFonts.ptSans(
              fontSize: width * 0.066,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),

          userRole == "Guide"
              ? SizedBox.shrink()
              : SizedBox(
                width: width * 0.3,
                child: DropdownButton<String>(
                  menuWidth: width * 0.5,
                  borderRadius: BorderRadius.circular(width * 0.02),

                  value:
                      userData['Active Vehicle'] ??
                      (vehicles.isNotEmpty ? vehicles.first['id'] : null),
                  underline: SizedBox(),
                  iconSize: width * 0.05,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      FirebaseFirestore.instance
                          .collection('Users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .update({'Active Vehicle': newValue});
                    }
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return vehicles.map<Widget>((vehicle) {
                      return Padding(
                        padding: EdgeInsets.only(right: width * 0.02),
                        child: Image.asset(
                          vehicleTypeIcons[vehicle['vehicleType']] ??
                              'assets/car_icons/sedan.png',
                          width: width * 0.1,
                          height: width * 0.1,
                          color: darkMode ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList();
                  },
                  items:
                      vehicles.map((vehicle) {
                        return DropdownMenuItem<String>(
                          value: vehicle['id'],
                          child: Row(
                            children: [
                              Image.asset(
                                vehicleTypeIcons[vehicle['vehicleType']] ??
                                    'assets/car_icons/sedan.png',
                                width: width * 0.08,
                                height: width * 0.08,
                                color: darkMode ? Colors.white : Colors.black,
                              ),
                              SizedBox(width: width * 0.02),
                              Flexible(
                                child: Text(
                                  vehicle['registration'],
                                  style: GoogleFonts.ptSans(
                                    fontSize: width * 0.035,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            navigatorKey.currentState?.pushNamed('/notification_screen');
          },
          icon: Stack(
            children: [
              Icon(
                Icons.notifications,
                color: darkMode ? Colors.white : Colors.black,
              ),
              hasUnviewedNotifications
                  ? Positioned(
                    right: 13,
                    top: 2,
                    child: Icon(
                      Icons.brightness_1,
                      color:
                          darkMode
                              ? Color.fromARGB(255, 52, 168, 235)
                              : Color.fromARGB(255, 1, 105, 170),
                      size: width * 0.022,
                    ),
                  )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ],
      backgroundColor:
          darkMode
              ? Color.fromARGB(255, 1, 105, 170)
              : Color.fromARGB(255, 52, 168, 235),
    );
  }
}
