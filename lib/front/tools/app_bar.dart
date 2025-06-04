import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/tools/firebase_service.dart';
import 'package:onemoretour/db/user_data/store_role.dart';
import 'package:onemoretour/front/tools/notification_notifier.dart';
import 'package:onemoretour/main.dart';
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
  final Map<String, String> vehicleTypeIcons = {
    'Sedan': "assets/car_icons/sedan.png",
    'Minivan': "assets/car_icons/mininvan.png",
    'SUV': "assets/car_icons/SUV.png",
    'Premium SUV': "assets/car_icons/premium_SUV.png",
    'Bus': "assets/car_icons/bus.png",
  };

  @override
  void initState() {
    try {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.watch(notificationsProvider.notifier).refresh();
      });
    } catch (e) {
      logger.e('Error to initialize appBar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    if (vehiclesAsync.isLoading) {
      return CircularProgressIndicator();
    }

    if (vehiclesAsync.hasError) {
      return Text('Error loading vehicles');
    }

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
      return SizedBox(
        width: width * 0.11,
        height: height * 0.052,
        child: CircularProgressIndicator(),
      );
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
          Expanded(
            child: Text(
              'Hi, $firstName!',
              style: GoogleFonts.ptSans(
                fontSize: width * 0.066,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
          Spacer(),

          userRole == "Guide"
              ? SizedBox.shrink()
              : AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: vehiclesAsync.when(
                  loading:
                      () => SizedBox(
                        key: ValueKey('loading'),
                        width: width * 0.3,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error:
                      (error, stack) => SizedBox(
                        key: ValueKey('error'),
                        width: width * 0.3,
                        child: Center(child: Text('Error')),
                      ),
                  data: (vehicles) {
                    if (vehicles.isEmpty) {
                      return SizedBox(
                        key: ValueKey('empty'),
                        width: width * 0.3,
                        child: Center(child: Text('No vehicles')),
                      );
                    }
                    return SizedBox(
                      key: ValueKey('dropdown'),
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
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          final userId = user.uid;
                          if (newValue != null) {
                            FirebaseFirestore.instance
                                .collection('Users')
                                .doc(userId)
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
                              bool isActive =
                                  (vehicle['id'] ==
                                      (userData['Active Vehicle'] ??
                                          (vehicles.isNotEmpty
                                              ? vehicles.first['id']
                                              : null)));

                              return DropdownMenuItem<String>(
                                value: vehicle['id'],
                                child: Row(
                                  children: [
                                    Image.asset(
                                      vehicleTypeIcons[vehicle['vehicleType']] ??
                                          'assets/car_icons/sedan.png',
                                      width: width * 0.08,
                                      height: width * 0.08,
                                      color:
                                          darkMode
                                              ? Colors.white
                                              : Colors.black,
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
                                    if (isActive) ...[
                                      SizedBox(width: width * 0.02),
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color.fromARGB(
                                          255,
                                          103,
                                          168,
                                          120,
                                        ),
                                        size: width * 0.045,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    );
                  },
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
                    right: width * 0.033,
                    top: height * 0.002,
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
