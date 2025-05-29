import 'package:onemoretour/back/rides_history/rides_provider.dart';
import 'package:onemoretour/db/user_data/store_role.dart';
import 'package:onemoretour/front/auth/waiting_page.dart';
import 'package:onemoretour/front/displayed_items/profile/deleting_account_page.dart';
import 'package:onemoretour/front/displayed_items/profile/profile_data.dart';
import 'package:onemoretour/front/displayed_items/profile/rides_history.dart';
import 'package:onemoretour/front/displayed_items/profile/vehicle_list.dart';
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
    final roleDetails = ref.watch(roleProvider);
    final userRole = roleDetails?['Role'];

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
                                  width: width * 0.02,
                                  rodStackItems: [],
                                  color: Colors.green,
                                  borderRadius: BorderRadius.zero,
                                ),
                                BarChartRodData(
                                  toY: unpaidValue,
                                  width: width * 0.02,
                                  rodStackItems: [],
                                  color: Colors.red,
                                  borderRadius: BorderRadius.zero,
                                ),
                              ],
                              barsSpace: width * 0.01,
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
              Material(
                color:
                    darkMode
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(width * 0.039),
                child: InkWell(
                  borderRadius: BorderRadius.circular(width * 0.039),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileData()),
                    );
                  },
                  child: Container(
                    width: width,
                    height: height * 0.065,
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
              ),
              Material(
                color:
                    darkMode
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(width * 0.039),
                child: InkWell(
                  borderRadius: BorderRadius.circular(width * 0.039),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RidesHistory()),
                    );
                  },
                  child: Container(
                    width: width,
                    height: height * 0.065,
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
              ),

              userRole == "Guide"
                  ? SizedBox.shrink()
                  : Material(
                    color:
                        darkMode
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(width * 0.039),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(width * 0.039),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehicleList(),
                          ),
                        );
                      },
                      child: Container(
                        width: width,
                        height: height * 0.065,
                        padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                        child: Row(
                          spacing: width * 0.03,
                          children: [
                            Image.asset(
                              'assets/car_icons/vehicle.png',
                              width: width * 0.061,
                              height: height * 0.028,
                              fit: BoxFit.fill,
                              color: darkMode ? Colors.white : Colors.black,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      Icon(Icons.error),
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
                  ),

              Material(
                color:
                    darkMode
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(width * 0.039),
                child: InkWell(
                  borderRadius: BorderRadius.circular(width * 0.039),
                  onTap: () async {
                    await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            backgroundColor:
                                darkMode ? Color(0xFF1E1E1E) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(width * 0.05),
                            ),
                            title: Text(
                              'Confirm Logout',
                              style: GoogleFonts.cabin(
                                color: darkMode ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.07,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to log out?',
                              style: GoogleFonts.cabin(
                                color:
                                    darkMode ? Colors.white70 : Colors.black54,
                                fontSize: width * 0.045,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.cabin(
                                    color:
                                        darkMode
                                            ? Colors.grey[400]
                                            : Colors.blueGrey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: width * 0.045,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      darkMode
                                          ? Color(0xFF34A8EB)
                                          : Color(0xFF007BFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      width * 0.03,
                                    ),
                                  ),
                                ),
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const WaitingPage(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                child: Text(
                                  'Log out',
                                  style: GoogleFonts.cabin(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: width * 0.045,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                  child: Container(
                    width: width,
                    height: height * 0.065,
                    padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                    child: Row(
                      spacing: width * 0.03,
                      children: [
                        Image.asset(
                          'assets/logout.png',
                          width: width * 0.061,
                          height: height * 0.028,
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
              ),

              Spacer(),
              Padding(
                padding: EdgeInsets.only(top: height * 0.02),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 231, 1, 55),
                    textStyle: GoogleFonts.cabin(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.045,
                    ),
                  ),
                  onPressed: () async {
                    final confirmDelete = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            backgroundColor:
                                darkMode ? Color(0xFF1E1E1E) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(width * 0.05),
                            ),
                            title: Text(
                              'Delete Profile',
                              style: GoogleFonts.cabin(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.05,
                                color: darkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete your profile? This action cannot be undone.',
                              style: GoogleFonts.cabin(
                                fontSize: width * 0.04,
                                color:
                                    darkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.cabin(
                                    fontWeight: FontWeight.bold,
                                    fontSize: width * 0.04,
                                    color:
                                        darkMode
                                            ? Colors.grey[400]
                                            : Colors.blueGrey,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    231,
                                    1,
                                    55,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.cabin(
                                    fontWeight: FontWeight.bold,
                                    fontSize: width * 0.04,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirmDelete == true && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeletingAccountPage(),
                        ),
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Delete Profile',
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.045,
                          color: const Color.fromARGB(255, 231, 1, 55),
                        ),
                      ),
                      SizedBox(height: height * 0.001),
                      Container(
                        width: width * 0.3,
                        height: height * 0.002,
                        color: const Color.fromARGB(255, 231, 1, 55),
                      ),
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
