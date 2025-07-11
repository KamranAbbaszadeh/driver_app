// This view displays the user's onboarding progress and provides action prompts.
// It guides the user through sending an application, submitting documents, and signing a contract.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/front/auth/waiting_page.dart';
import 'package:onemoretour/front/intro/route_navigator.dart';
import 'package:onemoretour/front/intro/welcome_page.dart';
import 'package:onemoretour/front/tools/bottom_bar_provider.dart';
import 'package:onemoretour/front/tools/notification_notifier.dart';
import 'package:onemoretour/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays user onboarding steps: application, personal details, and contract signing.
/// Shows progress indicators and 'Continue' buttons based on Firestore data.
class WaitingPageView extends ConsumerStatefulWidget {
  const WaitingPageView({super.key});

  @override
  ConsumerState<WaitingPageView> createState() => _WaitingPageViewState();
}

class _WaitingPageViewState extends ConsumerState<WaitingPageView> {
  /// Clears shared preferences and logs out the user.
  Future<void> handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  late final String? userId;
  late final String contractUrl;
  late final String customerSupport;
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      });
    } else {
      userId = user.uid;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.watch(notificationsProvider.notifier).refresh();
    });
    // Fetch customer support link from Firestore after user authentication.
    FirebaseFirestore.instance
        .collection('Details')
        .doc('CustomerSupport')
        .get()
        .then((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            customerSupport = data['URL'] ?? '';
          } else {
            customerSupport = '';
          }
        });
  }

  bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> launchCustomerSupport(String urlString) async {
    final Uri uri = Uri.parse(urlString);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final fallbackUri = getFallbackUri(urlString);
      if (fallbackUri != null && await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch app or fallback store link';
      }
    }
  }

  Uri? getFallbackUri(String originalUrl) {
    if (originalUrl.contains("wa.me") || originalUrl.contains("whatsapp")) {
      return Uri.parse(
        Platform.isIOS
            ? "https://apps.apple.com/us/app/whatsapp-messenger/id310633997"
            : "https://play.google.com/store/apps/details?id=com.whatsapp&hl=en",
      );
    } else if (originalUrl.contains("t.me") ||
        originalUrl.contains("telegram")) {
      return Uri.parse(
        Platform.isIOS
            ? "https://apps.apple.com/us/app/telegram-messenger/id686449807"
            : "https://play.google.com/store/apps/details?id=org.telegram.messenger&hl=en",
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    bool isSnackBarVisible = false;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final notifications = ref.watch(notificationsProvider);
    final hasUnviewedNotifications = notifications.any((notif) {
      return notif['isViewed'] == false;
    });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        actionsPadding: EdgeInsets.symmetric(horizontal: width * 0.019),
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.055),
              color:
                  darkMode
                      ? const Color.fromARGB(255, 40, 40, 40)
                      : const Color.fromARGB(255, 255, 255, 255),
            ),
            padding: EdgeInsets.zero,
            // Show notification icon with badge if there are unviewed notifications.
            child: Stack(
              children: [
                IconButton(
                  onPressed: () {
                    navigatorKey.currentState?.pushNamed(
                      '/notification_screen',
                    );
                  },
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.notifications,
                        color: darkMode ? Colors.white : Colors.black,
                      ),
                      hasUnviewedNotifications
                          ? Positioned(
                            left: width * 0.033,
                            top: height * 0.002,
                            child: Icon(
                              Icons.brightness_1,
                              color:
                                  darkMode
                                      ? Color.fromARGB(255, 1, 105, 170)
                                      : Color.fromARGB(255, 52, 168, 235),
                              size: width * 0.022,
                            ),
                          )
                          : SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: width * 0.019),

          Material(
            color: darkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
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
                            color: darkMode ? Colors.white70 : Colors.black54,
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
                          // Sign out user and redirect to WaitingPage after confirmation.
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
                              handleLogout(context);
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WaitingPage(),
                                  ),
                                  (route) => false,
                                );
                              }

                              ref.read(selectedIndexProvider.notifier).state =
                                  0;
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
              child: Image.asset(
                'assets/logout.png',
                width: width * 0.051,
                height: height * 0.02,
                fit: BoxFit.fill,
                color: darkMode ? Colors.white : Colors.black,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
              ),
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Users')
                .doc(currentUser.uid)
                .snapshots(),
        builder: (context, snapshot) {
          // Listen to real-time updates from the user's Firestore document.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No data found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          // Dynamically update contractUrl from Firestore data
          contractUrl = userData['ContractLink'] ?? '';

          bool applicationFormVerified = userData['Application Form Verified'];
          bool personalFormReceived =
              userData['Personal & Car Details Form'] == 'APPLICATION RECEIVED';
          bool personalFormApproved =
              userData['Personal & Car Details Form'] == 'APPLICATION APPROVED';
          bool personalFormVerified =
              userData['Personal & Car Details Form Verified'];
          bool contractSigned = userData['Contract Signing'] == 'SIGNED';
          bool applicationFormDenied = userData['Application Form Decline'];
          bool personalFormDenied = userData["Personal & Car Details Decline"];
          bool contractDenied = userData['Contract Signing Decline'];

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Salam ${userData['First Name']}!',
                      style: GoogleFonts.daysOne(
                        fontSize: width * 0.076,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                    Text(
                      'Would like to become a One More Tour Partner?',
                      style: GoogleFonts.openSans(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.05,
                      ),
                    ),
                    SizedBox(height: height * 0.015),
                    Text(
                      'Please follow the steps below to make that magic happen.',
                      style: TextStyle(fontSize: width * 0.045),
                    ),
                    SizedBox(height: height * 0.025),
                    Divider(
                      color: Colors.grey[400],
                      thickness: height * 0.0005,
                    ),
                    SizedBox(height: height * 0.025),
                    // Send application section - shows current status and instructions.
                    //SEND APPLICATION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: width * 0.025,
                      children: [
                        SizedBox(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      149,
                                      189,
                                      189,
                                      189,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    width * 0.063,
                                  ),
                                ),
                                width: width * 0.127,
                                height: height * 0.058,
                                child: Icon(
                                  Icons.assignment_outlined,
                                  size: width * 0.076,
                                  color:
                                      applicationFormDenied
                                          ? const Color.fromARGB(
                                            255,
                                            231,
                                            1,
                                            55,
                                          )
                                          : const Color.fromARGB(
                                            255,
                                            18,
                                            213,
                                            70,
                                          ),
                                ),
                              ),
                              SizedBox(height: height * 0.015),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        personalFormReceived ||
                                                personalFormApproved
                                            ? const Color.fromARGB(
                                              149,
                                              189,
                                              189,
                                              189,
                                            )
                                            : const Color.fromARGB(
                                              91,
                                              110,
                                              109,
                                              109,
                                            ),
                                  ),
                                ),
                                height: height * 0.08,
                                width: width * 0.0025,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send application',
                                  style: GoogleFonts.daysOne(
                                    fontSize: width * 0.05,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'We\'ll be in touch about next steps once we\'ve reviewed your application.',
                                  style: GoogleFonts.openSans(
                                    fontSize: width * 0.038,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                                SizedBox(height: height * 0.020),
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        applicationFormDenied
                                            ? const Color.fromARGB(
                                              255,
                                              231,
                                              1,
                                              55,
                                            )
                                            : const Color.fromARGB(
                                              255,
                                              18,
                                              213,
                                              70,
                                            ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  height: height * 0.03,
                                  width: width * 0.5,
                                  child: Center(
                                    child: Text(
                                      userData['Application Form'],
                                      style: GoogleFonts.openSans(
                                        fontSize: width * 0.03,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.015),
                    // Contract Details section - shows current status and instructions.
                    //CONTRACT DETAILS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: width * 0.025,
                      children: [
                        SizedBox(
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        personalFormReceived ||
                                                personalFormApproved
                                            ? const Color.fromARGB(
                                              149,
                                              189,
                                              189,
                                              189,
                                            )
                                            : const Color.fromARGB(
                                              91,
                                              110,
                                              109,
                                              109,
                                            ),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    width * 0.063,
                                  ),
                                ),
                                width: width * 0.127,
                                height: height * 0.058,
                                child: Icon(
                                  Icons.task_outlined,
                                  size: width * 0.076,
                                  color:
                                      personalFormReceived ||
                                              personalFormApproved
                                          ? personalFormDenied
                                              ? const Color.fromARGB(
                                                255,
                                                231,
                                                1,
                                                55,
                                              )
                                              : const Color.fromARGB(
                                                255,
                                                18,
                                                213,
                                                70,
                                              )
                                          : const Color.fromARGB(
                                            91,
                                            110,
                                            109,
                                            109,
                                          ),
                                ),
                              ),

                              SizedBox(height: height * 0.015),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        personalFormReceived ||
                                                personalFormApproved
                                            ? const Color.fromARGB(
                                              149,
                                              189,
                                              189,
                                              189,
                                            )
                                            : const Color.fromARGB(
                                              91,
                                              110,
                                              109,
                                              109,
                                            ),
                                  ),
                                ),
                                height: height * 0.08,
                                width: width * 0.0025,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Contract Details',
                                  style: GoogleFonts.daysOne(
                                    fontSize: width * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        personalFormReceived ||
                                                personalFormApproved
                                            ? Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color
                                            : const Color.fromARGB(
                                              91,
                                              110,
                                              109,
                                              109,
                                            ),
                                  ),
                                ),
                                Text(
                                  'Please fill the information needed for making a Partner contract with One More Tour',
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  style: GoogleFonts.openSans(
                                    fontSize: width * 0.038,
                                    fontWeight: FontWeight.normal,
                                    color:
                                        personalFormReceived ||
                                                personalFormApproved
                                            ? Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color
                                            : const Color.fromARGB(
                                              91,
                                              110,
                                              109,
                                              109,
                                            ),
                                  ),
                                ),
                                personalFormReceived || personalFormApproved
                                    ? Column(
                                      children: [
                                        SizedBox(height: height * 0.015),
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                personalFormDenied
                                                    ? const Color.fromARGB(
                                                      255,
                                                      231,
                                                      1,
                                                      55,
                                                    )
                                                    : const Color.fromARGB(
                                                      255,
                                                      18,
                                                      213,
                                                      70,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              width * 0.025,
                                            ),
                                          ),
                                          height: height * 0.03,
                                          width: width * 0.5,
                                          child: Center(
                                            child: Text(
                                              userData['Personal & Car Details Form'],
                                              style: GoogleFonts.openSans(
                                                fontSize: width * 0.03,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                    : SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.015),
                    // Contract Signing section - shows current status and instructions.
                    //CONTRACT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: width * 0.025,
                      children: [
                        SizedBox(
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        contractSigned
                                            ? const Color.fromARGB(
                                              149,
                                              189,
                                              189,
                                              189,
                                            )
                                            : const Color.fromARGB(
                                              91,
                                              110,
                                              109,
                                              109,
                                            ),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    width * 0.063,
                                  ),
                                ),
                                width: width * 0.127,
                                height: height * 0.058,
                                child: Icon(
                                  Icons.handshake,
                                  size: width * 0.076,
                                  color:
                                      contractSigned
                                          ? contractDenied
                                              ? const Color.fromARGB(
                                                255,
                                                231,
                                                1,
                                                55,
                                              )
                                              : const Color.fromARGB(
                                                255,
                                                18,
                                                213,
                                                70,
                                              )
                                          : const Color.fromARGB(
                                            91,
                                            110,
                                            109,
                                            109,
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Contract Signing',
                                  style: GoogleFonts.daysOne(
                                    fontSize: width * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        contractSigned
                                            ? Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color
                                            : const Color.fromARGB(
                                              91,
                                              110,
                                              109,
                                              109,
                                            ),
                                  ),
                                ),
                                Text(
                                  'Review and sign the partnership agreement to officially become a One More Tour Partner',
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  style: GoogleFonts.openSans(
                                    fontSize: width * 0.038,
                                    fontWeight: FontWeight.normal,
                                    color:
                                        contractSigned
                                            ? Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color
                                            : const Color.fromARGB(
                                              91,
                                              110,
                                              109,
                                              109,
                                            ),
                                  ),
                                ),
                                contractSigned
                                    ? Column(
                                      children: [
                                        SizedBox(height: height * 0.015),
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                contractDenied
                                                    ? const Color.fromARGB(
                                                      255,
                                                      231,
                                                      1,
                                                      55,
                                                    )
                                                    : const Color.fromARGB(
                                                      255,
                                                      18,
                                                      213,
                                                      70,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              width * 0.025,
                                            ),
                                          ),
                                          height: height * 0.03,
                                          width: width * 0.5,
                                          child: Center(
                                            child: Text(
                                              userData['Contract Signing'],
                                              style: GoogleFonts.openSans(
                                                fontSize: width * 0.03,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                    : SizedBox.shrink(),
                                SizedBox(height: height * 0.025),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    Divider(
                      color: Colors.grey[400],
                      thickness: height * 0.0005,
                    ),
                    SizedBox(height: height * 0.025),
                    // Display appropriate 'Continue' button depending on user's progress in onboarding.
                    userData['Application Form Decline'] == true
                        ? GestureDetector(
                          onTap: () {
                            try {
                              navigatorKey.currentState?.pushNamed(
                                '/application_form',
                              );
                            } on Exception catch (e) {
                              logger.e(
                                'Error navigating to personal data form: $e',
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  darkMode
                                      ? Color.fromARGB(255, 52, 168, 235)
                                      : Color.fromARGB(177, 0, 134, 179),
                              borderRadius: BorderRadius.circular(
                                width * 0.019,
                              ),
                            ),
                            width: width,
                            height: height * 0.058,
                            child: Center(
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  color:
                                      darkMode
                                          ? const Color.fromARGB(132, 0, 0, 0)
                                          : const Color.fromARGB(
                                            187,
                                            255,
                                            255,
                                            255,
                                          ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )
                        : (applicationFormVerified &&
                                !personalFormVerified &&
                                userData['Personal & Car Details Form'] ==
                                    "PENDING") ||
                            userData['Personal & Car Details Decline'] == true
                        ? GestureDetector(
                          onTap: () {
                            try {
                              navigatorKey.currentState?.pushNamed(
                                '/personal_data_form',
                              );
                            } on Exception catch (e) {
                              logger.e(
                                'Error navigating to personal data form: $e',
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  darkMode
                                      ? Color.fromARGB(255, 52, 168, 235)
                                      : Color.fromARGB(177, 0, 134, 179),
                              borderRadius: BorderRadius.circular(
                                width * 0.019,
                              ),
                            ),
                            width: width,
                            height: height * 0.058,
                            child: Center(
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  color:
                                      darkMode
                                          ? const Color.fromARGB(132, 0, 0, 0)
                                          : const Color.fromARGB(
                                            187,
                                            255,
                                            255,
                                            255,
                                          ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )
                        : personalFormVerified &&
                            applicationFormVerified &&
                            userData['Contract Signing'] == "PENDING"
                        ? GestureDetector(
                          onTap: () {
                            Navigator.of(
                              context,
                            ).push(route(title: 'Contract', url: contractUrl));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  darkMode
                                      ? Color.fromARGB(255, 52, 168, 235)
                                      : Color.fromARGB(177, 0, 134, 179),
                              borderRadius: BorderRadius.circular(
                                width * 0.019,
                              ),
                            ),
                            width: width,
                            height: height * 0.058,
                            child: Center(
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  color:
                                      darkMode
                                          ? const Color.fromARGB(132, 0, 0, 0)
                                          : const Color.fromARGB(
                                            187,
                                            255,
                                            255,
                                            255,
                                          ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )
                        : SizedBox.shrink(),
                    SizedBox(height: height * 0.01),
                    // Option for the user to contact support if they need help during onboarding.
                    GestureDetector(
                      onTap: () {
                        if (isValidUrl(customerSupport)) {
                          launchCustomerSupport(customerSupport);
                        } else {
                          if (isSnackBarVisible) return;

                          isSnackBarVisible = true;

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Something went wrong. Please try again later.',
                                  style: TextStyle(
                                    color:
                                        darkMode ? Colors.black : Colors.white,
                                  ),
                                ),
                                backgroundColor:
                                    darkMode ? Colors.white : Colors.black,
                                duration: const Duration(seconds: 3),
                              ),
                            ).closed.then((_) {
                              isSnackBarVisible = false;
                            });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              darkMode
                                  ? const Color.fromARGB(111, 9, 133, 234)
                                  : const Color.fromARGB(99, 119, 207, 250),
                          borderRadius: BorderRadius.circular(width * 0.019),
                        ),
                        width: width,
                        height: height * 0.058,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              color: const Color.fromARGB(255, 33, 163, 243),
                            ),
                            SizedBox(width: width * 0.012),
                            Text(
                              'Contact with support',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 33, 163, 243),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.015),
                    Center(
                      child: Text(
                        'We will get back to you as soon as possible',
                        style: GoogleFonts.openSans(
                          fontSize: width * 0.033,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color!.withAlpha(151),
                        ),
                      ),
                    ),

                    SizedBox(height: height * 0.025),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
