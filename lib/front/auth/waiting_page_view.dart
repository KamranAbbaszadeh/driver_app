import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaitingPageView extends StatelessWidget {
  WaitingPageView({super.key});

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: darkMode ? Colors.black : Colors.white,
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
            child: IconButton(
              onPressed: () {
                navigatorKey.currentState?.pushNamed('/notification_screen');
                print('Icon works well');
              },
              icon: Icon(Icons.notifications_active),
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

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Salam ${userData['First Name']}!',
                  style: GoogleFonts.daysOne(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: height * 0.025),
                Text(
                  'Would like to become a One More Tour Partner?',
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: height * 0.015),
                Text(
                  'Please follow the steps below to make that magic happen.',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: height * 0.025),
                Divider(color: Colors.grey[400], thickness: height * 0.0005),
                SizedBox(height: height * 0.025),
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
                                color: const Color.fromARGB(149, 189, 189, 189),
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
                              color: const Color.fromARGB(255, 27, 194, 32),
                            ),
                          ),
                          SizedBox(height: height * 0.015),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    personalFormReceived
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
                        height: height * 0.14,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send application',
                              style: GoogleFonts.daysOne(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'We\'ll be in touch about next steps once we\'ve reviewed your application.',
                              style: GoogleFonts.openSans(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                            SizedBox(height: height * 0.020),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 27, 194, 32),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              height: height * 0.03,
                              width: width * 0.4,
                              child: Center(
                                child: Text(
                                  userData['Application Form'],
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
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
                                    personalFormReceived
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
                                  personalFormReceived
                                      ? const Color.fromARGB(255, 27, 194, 32)
                                      : const Color.fromARGB(91, 110, 109, 109),
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
                              'Contract',
                              style: GoogleFonts.daysOne(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    personalFormReceived
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
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                                color:
                                    personalFormReceived
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
                            personalFormReceived
                                ? Column(
                                  children: [
                                    SizedBox(height: height * 0.015),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          27,
                                          194,
                                          32,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      height: height * 0.03,
                                      width: width * 0.4,
                                      child: Center(
                                        child: Text(
                                          userData['Personal & Car Details Form'],
                                          style: GoogleFonts.openSans(
                                            fontSize: 12,
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
                SizedBox(height: height * 0.015),
                Divider(color: Colors.grey[400], thickness: height * 0.0005),
                SizedBox(height: height * 0.025),
                applicationFormVerified
                    ? GestureDetector(
                      onTap: () {
                        navigatorKey.currentState?.pushNamed(
                          '/personal_data_form',
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              darkMode
                                  ? Color.fromARGB(255, 52, 168, 235)
                                  : Color.fromARGB(177, 0, 134, 179),
                          borderRadius: BorderRadius.circular(width * 0.019),
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
                  onTap: () {
                    FirebaseAuth.instance.signOut();
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
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color!.withAlpha(151),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
