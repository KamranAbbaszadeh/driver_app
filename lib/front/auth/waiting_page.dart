// Entry gate that determines whether to display the welcome page, onboarding flow, or main home screen.
// Listens to authentication and registration status using nested StreamBuilders.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/auth/is_deleting_profile_provider.dart';
import 'package:onemoretour/front/auth/waiting_page_view.dart';
import 'package:onemoretour/front/intro/welcome_page.dart';
import 'package:onemoretour/front/displayed_items/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main entry page for authenticated users.
/// Redirects based on whether the user is signed in, has valid Firestore data,
/// and has completed registration. Handles deletion and null-state fallbacks.
class WaitingPage extends ConsumerStatefulWidget {
  const WaitingPage({super.key});

  @override
  ConsumerState<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends ConsumerState<WaitingPage> {
  /// Creates a stream of the user's Firestore document to track real-time updates.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStatusStream(
    String uid,
  ) {
    return FirebaseFirestore.instance.collection('Users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to authentication state changes to determine logged-in user.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          final user = authSnapshot.data!;

          // Handle edge case where FirebaseAuth.instance.currentUser becomes null after auth.
          if (FirebaseAuth.instance.currentUser == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomePage()),
                (_) => false,
              );
            });
            return const SizedBox.shrink();
          }

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

              // Extract registration completion flag from Firestore user data.
              final userData = userStatusSnapshot.data!.data();
              final isRegistrationCompleted =
                  userData?['Registration Completed'] ?? false;

              // Route to the home page if registration is complete, otherwise show onboarding steps.
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
