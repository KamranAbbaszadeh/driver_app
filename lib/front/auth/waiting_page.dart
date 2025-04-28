import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/front/auth/waiting_page_view.dart';
import 'package:driver_app/front/intro/welcome_page.dart';
import 'package:driver_app/front/displayed_items/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WaitingPage extends StatefulWidget {
  const WaitingPage({super.key});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStatusStream(
    String uid,
  ) {
    return FirebaseFirestore.instance.collection('Users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          final user = authSnapshot.data!;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: getUserStatusStream(user.uid),
            builder: (context, userStatusSnapshot) {
              if (userStatusSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userStatusSnapshot.hasError ||
                  !userStatusSnapshot.hasData ||
                  userStatusSnapshot.data?.data() == null) {
                FirebaseAuth.instance.signOut();
                return WelcomePage();
              }

              final userData = userStatusSnapshot.data!.data();
              final isRegistrationCompleted =
                  userData?['Registration Completed'] ?? false;

              if (isRegistrationCompleted) {
                return HomePage();
              } else {
                return WaitingPageView();
              }
            },
          );
        } else {
          return WelcomePage();
        }
      },
    );
  }
}
