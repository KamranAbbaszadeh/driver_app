import 'package:onemoretour/front/displayed_items/restart_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.061),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: width * 0.254, color: Colors.black),
                SizedBox(height: height * 0.028),
                Text(
                  'No Internet Connection',
                  style: GoogleFonts.cabin(
                    fontSize: width * 0.066,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: height * 0.018),
                Text(
                  'It seems you\'re not connected to the internet.\nPlease check your connection and try again.',
                  style: TextStyle(
                    fontSize: width * 0.04,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: height * 0.037),
                ElevatedButton.icon(
                  onPressed: () {
                    RestartWidget.restartApp(context);
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: darkMode ? Colors.black : Colors.white,
                  ),
                  label: Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.w500,
                      color: darkMode ? Colors.black : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.081,
                      vertical: height * 0.016,
                    ),
                    backgroundColor: darkMode ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.025),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
