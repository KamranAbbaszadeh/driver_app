import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/auth/is_deleting_profile_provider.dart';
import 'package:onemoretour/front/auth/waiting_page_view.dart';
import 'package:onemoretour/front/intro/welcome_page.dart';
import 'package:onemoretour/front/displayed_items/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WaitingPage extends ConsumerStatefulWidget {
  const WaitingPage({super.key});

  @override
  ConsumerState<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends ConsumerState<WaitingPage> {
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
              final isDeleting = ref.read(isDeletingProfileProvider);
              if (userStatusSnapshot.hasError ||
                  !userStatusSnapshot.hasData ||
                  userStatusSnapshot.data?.data() == null) {
                if (!isDeleting) {
                  FirebaseAuth.instance.signOut();
                  return WelcomePage();
                }
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
