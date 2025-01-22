import 'package:driver_app/front/auth/waiting_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // final darkMode =
    //     MediaQuery.of(context).platformBrightness == Brightness.dark;
    // final height = MediaQuery.of(context).size.height;
    // final width = MediaQuery.of(context).size.width;
    return Center(
      child: TextButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => WaitingPage()),
            (route) => false,
          );
        },
        child: Text('Sign out'),
      ),
    );
  }
}
