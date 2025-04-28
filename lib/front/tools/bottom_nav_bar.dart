import 'package:bottom_bar_matu/bottom_bar_matu.dart';
import 'package:driver_app/front/tools/bottom_bar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Material(
        elevation: height * 0.008,
        color: Colors.transparent,
        child: BottomBarDoubleBullet(
          selectedIndex: selectedIndex,
          backgroundColor: darkMode ? Colors.black : Colors.white,
          circle1Color: Color.fromARGB(255, 1, 105, 170),
          circle2Color: Color.fromARGB(255, 52, 168, 235),
          height: height * 0.07,
          color: darkMode ? Colors.white : Colors.black,
          onSelect:
              (value) => ref.read(selectedIndexProvider.notifier).state = value,
          items: [
            BottomBarItem(
              iconData: Icons.home,
              label: 'Home',
              labelTextStyle: GoogleFonts.daysOne(),
            ),
            BottomBarItem(
              iconData: Icons.search,
              label: 'Rides',
              labelTextStyle: GoogleFonts.daysOne(),
            ),
            BottomBarItem(
              iconData: Icons.person,
              label: 'Profile',
              labelTextStyle: GoogleFonts.daysOne(),
            ),
          ],
        ),
      ),
    );
  }
}
