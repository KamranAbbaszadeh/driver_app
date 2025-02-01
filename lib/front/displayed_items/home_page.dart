import 'package:driver_app/front/displayed_items/ride_page.dart';
import 'package:driver_app/front/tools/app_bar.dart';
import 'package:driver_app/front/tools/bottom_bar_provider.dart';
import 'package:driver_app/front/tools/bottom_nav_bar.dart';
import 'package:driver_app/front/tools/list_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final index = ref.watch(selectedIndexProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.075),
        child: BuildAppBar(),
      ),
      body: listNavBar[selectedIndex],
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton:
          index == 0
              ? Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RidePage()),
                    );
                  },
                  child: Container(
                    width: width,
                    height: height * 0.06,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width * 0.019),
                      color:
                          darkMode
                              ? Color.fromARGB(255, 52, 168, 235)
                              : Color.fromARGB(255, 1, 105, 170),
                    ),
                    child: Center(
                      child: Text(
                        'Start Ride',
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.06,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
