// Welcome screen shown to users before signing in.
// Includes animated logo, sign-in and registration options, and terms link.

import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/front/auth/forms/application_forms/application_form.dart';
import 'package:onemoretour/front/intro/route_navigator.dart';
import 'package:onemoretour/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// A landing page widget displayed before user authentication.
/// Provides animation, sign-in with email, and an option to apply as a driver or guide.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _logoAnimation;
  late Animation<Offset> _contentAnimation;

  @override
  @override
  void initState() {
    try {
      super.initState();
      // Initialize animation controller and entry animations.
      _controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 5),
      );

      _logoAnimation = Tween<Offset>(
        begin: Offset(0, -1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      );

      _contentAnimation = Tween<Offset>(
        begin: Offset(0, 1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.5, 1.0, curve: Curves.easeOut),
        ),
      );

      // Start the animation after a short delay if widget is mounted.
      Future.delayed(Duration(milliseconds: 1), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } catch (e) {
      logger.e('Error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch screen dimensions and brightness for responsive layout and theming.
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    TextStyle defaultStyle = TextStyle(color: Colors.grey, fontSize: 14);
    TextStyle linkStyle = TextStyle(color: Colors.blue);
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final logo = 'assets/splash/onemoretour.png';
    // Build the main scaffold with animated logo and content.
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Center(
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        darkMode
                            ? [Color.fromARGB(255, 1, 105, 170), Colors.black]
                            : [Color.fromARGB(255, 52, 168, 235), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    tileMode: TileMode.decal,
                  ),
                ),
                child: Stack(
                  children: [
                    SlideTransition(
                      position: _logoAnimation,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: height * 0.226,
                          width: width * 0.763,
                          child: Center(
                            child: Image.asset(logo, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _contentAnimation,
                      child: Padding(
                        padding: EdgeInsets.only(top: height * 0.25),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Lottie.asset(
                              'assets/welcome/Animation_Welcome.json',
                              fit: BoxFit.fill,
                              reverse: false,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(height: height * 0.027),
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to email authentication page.
                                    navigatorKey.currentState?.pushNamed(
                                      '/auth_email',
                                    );
                                  },
                                  child: Container(
                                    height: height * 0.058,
                                    width: width * 0.923,
                                    decoration: BoxDecoration(
                                      color:
                                          darkMode
                                              ? Color.fromARGB(
                                                255,
                                                52,
                                                168,
                                                235,
                                              )
                                              : Color.fromARGB(
                                                255,
                                                1,
                                                105,
                                                170,
                                              ),
                                      borderRadius: BorderRadius.circular(
                                        width * 0.019,
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.030,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: width * 0.127,
                                          height: height * 0.035,
                                          child: Icon(
                                            Icons.email,
                                            color:
                                                darkMode
                                                    ? Colors.black87
                                                    : Colors.grey.shade300,
                                            size: width * 0.08,
                                          ),
                                        ),
                                        SizedBox(width: width * 0.12),
                                        Text(
                                          'Sign in with email',
                                          style: TextStyle(
                                            color:
                                                darkMode
                                                    ? Colors.black87
                                                    : Colors.grey.shade300,
                                            fontWeight: FontWeight.w700,
                                            fontSize: width * 0.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.057),
                                Text(
                                  'Want to become a driver or a tour guide?',
                                  style: GoogleFonts.roboto(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.normal,
                                    fontSize: width * 0.04,
                                  ),
                                ),
                                SizedBox(height: height * 0.018),
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to the application form for new drivers or guides.
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ApplicationForm(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: height * 0.058,
                                    width: width * 0.923,
                                    decoration: BoxDecoration(
                                      color:
                                          darkMode
                                              ? Color.fromARGB(143, 0, 51, 82)
                                              : Color.fromARGB(
                                                136,
                                                181,
                                                224,
                                                249,
                                              ),
                                      borderRadius: BorderRadius.circular(
                                        width * 0.019,
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.030,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Apply now',
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            29,
                                            145,
                                            212,
                                          ),
                                          fontWeight: FontWeight.w400,
                                          fontSize: width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.025),
                                RichText(
                                  text: TextSpan(
                                    style: defaultStyle,
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: 'By signin in you accept ',
                                      ),
                                      TextSpan(
                                        text: 'the terms and conditions',
                                        style: linkStyle,
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = () {
                                                // Open terms and conditions page in a webview.
                                                Navigator.of(context).push(
                                                  route(
                                                    title: 'Terms & Conditions',
                                                    url:
                                                        'https://onemoretour.com/terms',
                                                  ),
                                                );
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
