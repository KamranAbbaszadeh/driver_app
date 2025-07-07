// A fallback page shown when no internet connection is detected.
// Displays an offline message with a retry button that checks connectivity and redirects if online.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A UI screen to inform users about lack of internet connectivity.
/// Provides a "Try Again" button to check connection and redirect to the waiting screen.
class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect if dark mode is active for dynamic theming.
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    // Get screen dimensions for responsive sizing.
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    // Main layout structure for the no internet page.
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.061),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon to indicate lack of connectivity.
                Icon(Icons.wifi_off, size: width * 0.254, color: Colors.black),
                SizedBox(height: height * 0.028),
                // Main headline explaining the connectivity issue.
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
                // Additional message suggesting user actions.
                Text(
                  'It seems you\'re not connected to the internet.\nPlease check your connection and try again.',
                  style: TextStyle(
                    fontSize: width * 0.04,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: height * 0.037),
                // "Try Again" button to recheck internet connection and proceed if online.
                ElevatedButton.icon(
                  onPressed: () async {
                    var connectivityResult =
                        await Connectivity().checkConnectivity();
                    // If there is any network connection, navigate to the waiting screen.
                    if (!connectivityResult.contains(ConnectivityResult.none)) {
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          '/waiting_screen',
                        );
                      }
                    }
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
