import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver_app/back/tools/firebase_service.dart';
import 'package:driver_app/front/tools/notification_notifier.dart';
import 'package:driver_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildAppBar extends ConsumerStatefulWidget {
  const BuildAppBar({super.key});

  @override
  ConsumerState<BuildAppBar> createState() => _BuildAppBarState();
}

class _BuildAppBarState extends ConsumerState<BuildAppBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.watch(notificationsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final hasUnviewedNotifications = ref.watch(notificationsProvider);
    

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
