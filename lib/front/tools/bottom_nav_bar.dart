// Custom Bottom Navigation Bar using bottom_bar_matu with Riverpod state management.

import 'package:bottom_bar_matu/bottom_bar_matu.dart';
import 'package:onemoretour/front/tools/bottom_bar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// A bottom navigation bar with three tabs: Home, Rides, and Profile.
/// Uses Riverpod to manage and respond to tab selection state.
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the currently selected tab index from Riverpod provider.
    final selectedIndex = ref.watch(selectedIndexProvider);
    // Detect current system brightness to apply appropriate color scheme.
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    // Get screen height for responsive sizing.
    final height = MediaQuery.of(context).size.height;
    // Main container for Bottom Navigation with elevation and padding.
    return Material(
      elevation: height * 0.008,
      color: darkMode ? Colors.black : Colors.white,
      child: Padding(
        padding: EdgeInsets.only(bottom: height * 0.013),
        child: BottomBarDoubleBullet(
          selectedIndex: selectedIndex,
          backgroundColor: darkMode ? Colors.black : Colors.white,
          circle1Color: Color.fromARGB(255, 1, 105, 170),
          circle2Color: Color.fromARGB(255, 52, 168, 235),
          height: height * 0.1,

          color: darkMode ? Colors.white : Colors.black,
          // Update selected index in Riverpod state when a tab is selected.
          onSelect:
              (value) => ref.read(selectedIndexProvider.notifier).state = value,
          // Define the tab items: Home, Rides, and Profile.
          items: [
            // Home tab
            BottomBarItem(
              iconData: Icons.home,
              label: 'Home',
              labelTextStyle: GoogleFonts.daysOne(),
            ),
            // Rides tab
            BottomBarItem(
              iconData: Icons.search,
              label: 'Rides',
              labelTextStyle: GoogleFonts.daysOne(),
            ),
            // Profile tab
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
