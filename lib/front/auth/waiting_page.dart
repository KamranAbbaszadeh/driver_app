import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/front/auth/waiting_page_view.dart';
import 'package:driver_app/front/intro/welcome_page.dart';
import 'package:driver_app/front/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WaitingPage extends StatefulWidget {
  const WaitingPage({super.key});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  Future<bool> checkUserStatus(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('Users').doc(uid).get();

    return doc.data()?['Registration Completed'];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return FutureBuilder<bool>(
            future: checkUserStatus(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text("Error loading data"));
              }

              if (snapshot.data == true) {
                return MainPage();
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
