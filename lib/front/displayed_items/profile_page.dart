import 'package:driver_app/back/rides_history/rides_provider.dart';
import 'package:driver_app/front/auth/waiting_page.dart';
import 'package:driver_app/front/displayed_items/profile/profile_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    ref.watch(ridesHistoryProvider);
    final earningsMap = ref.read(ridesHistoryProvider.notifier).earningsByDate;
    final dates = earningsMap.keys.toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                darkMode
                    ? [Color.fromARGB(255, 1, 105, 170), Colors.black]
                    : [Color.fromARGB(255, 52, 168, 235), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.02),
          child: Column(
            spacing: height * 0.008,
            children: [
              SizedBox(
                height: height * 0.35,
                width: width,
                child: Column(
                  spacing: height * 0.01,
                  children: [
                    Text(
                      "Earnings",
                      style: GoogleFonts.cabin(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.05,
                      ),
                    ),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              direction: TooltipDirection.bottom,
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                            ),
                          ),
                          alignment: BarChartAlignment.spaceAround,
                          borderData: FlBorderData(
                            border: Border(
                              bottom: BorderSide(
                                color: const Color.fromARGB(255, 185, 185, 185),
                                width: width * 0.002,
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: false),
                          barGroups: List.generate(dates.length, (index) {
                            final data = earningsMap[dates[index]]!;
                            final paidValue = data[true] ?? 0.0;
                            final unpaidValue = data[false] ?? 0.0;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: paidValue,
                                  width: 8,
                                  rodStackItems: [],
                                  color: Colors.green,
                                  borderRadius: BorderRadius.zero,
                                ),
                                BarChartRodData(
                                  toY: unpaidValue,
                                  width: 8,
                                  rodStackItems: [],
                                  color: Colors.red,
                                  borderRadius: BorderRadius.zero,
                                ),
                              ],
                              barsSpace: 4,
                            );
                          }),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  int index = value.toInt();
                                  if (index < 0 || index >= dates.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final parts = dates[index].split('-');
                                  final date = DateTime(
                                    int.parse(parts[0]),
                                    int.parse(parts[1]),
                                  );
                                  return Text(
                                    DateFormat.MMM().format(date),
                                    style: GoogleFonts.cabin(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.04,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileData()),
                  );
                },
                child: Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.039),
                    color: const Color.fromARGB(100, 193, 192, 192),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                  child: Row(
                    spacing: width * 0.03,
                    children: [
                      Icon(Icons.person_2_outlined),
                      Text(
                        "Profile",
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.05,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.039),
                    color: const Color.fromARGB(100, 193, 192, 192),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                  child: Row(
                    spacing: width * 0.03,
                    children: [
                      Icon(Icons.history_toggle_off_sharp),
                      Text(
                        "Ride History",
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.05,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {},
                child: Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.039),
                    color: const Color.fromARGB(100, 193, 192, 192),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                  child: Row(
                    spacing: width * 0.03,
                    children: [
                      Image.asset(
                        'assets/vehicle.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.fill,
                        color: darkMode ? Colors.white : Colors.black,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(Icons.error),
                      ),
                      Text(
                        "My Vehicles",
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.05,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WaitingPage()),
                  );
                },
                child: Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.039),
                    color: const Color.fromARGB(100, 193, 192, 192),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                  child: Row(
                    spacing: width * 0.03,
                    children: [
                      Image.asset(
                        'assets/logout.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.fill,
                        color: darkMode ? Colors.white : Colors.black,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(Icons.error),
                      ),
                      Text(
                        "Log out",
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.05,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
