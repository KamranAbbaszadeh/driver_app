import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/front/intro/welcome_page.dart';
import 'package:onemoretour/front/tools/notification_notifier.dart';
import 'package:onemoretour/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class WaitingPageView extends ConsumerStatefulWidget {
  const WaitingPageView({super.key});

  @override
  ConsumerState<WaitingPageView> createState() => _WaitingPageViewState();
}

class _WaitingPageViewState extends ConsumerState<WaitingPageView> {
  late final String? userId;

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
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final notifications = ref.watch(notificationsProvider);
    final hasUnviewedNotifications = notifications.any((notif) {
      return notif['isViewed'] == false;
    });

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        actionsPadding: EdgeInsets.symmetric(horizontal: width * 0.019),
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
                            right: width * 0.033,
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
        ],
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No data found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

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
                                              10,
                                            ),
                                          ),
                                          height: height * 0.03,
                                          width: width * 0.4,
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
                                              10,
                                            ),
                                          ),
                                          height: height * 0.03,
                                          width: width * 0.4,
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
                            navigatorKey.currentState?.pushNamed(
                              '/contract_sign',
                            );
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
                    GestureDetector(
                      onTap: () {},
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
