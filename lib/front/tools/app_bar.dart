import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver_app/back/tools/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildAppBar extends ConsumerWidget {
  const BuildAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

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
      actions: [Icon(Icons.more_vert, size: width * 0.101)],
      backgroundColor:
          darkMode
              ? Color.fromARGB(255, 1, 105, 170)
              : Color.fromARGB(255, 52, 168, 235),
    );
  }
}
