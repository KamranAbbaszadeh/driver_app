import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/map_and_location/ride_flow_provider.dart';
import 'package:onemoretour/back/ride/ride_state.dart';
import 'package:onemoretour/back/rides_history/rides_provider.dart';
import 'package:onemoretour/back/tools/firebase_service.dart';
import 'package:onemoretour/back/tools/subscription_manager.dart';
import 'package:onemoretour/back/user/user_data_provider.dart';
import 'package:onemoretour/db/user_data/store_role.dart';
import 'package:onemoretour/front/intro/welcome_page.dart';
import 'package:onemoretour/front/tools/notification_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DeletingAccountPage extends ConsumerStatefulWidget {
  const DeletingAccountPage({super.key});

  @override
  ConsumerState<DeletingAccountPage> createState() =>
      _DeletingAccountPageState();
}

class _DeletingAccountPageState extends ConsumerState<DeletingAccountPage> {
  bool _hasStartedDeleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStartedDeleting) {
      _hasStartedDeleting = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        _deleteUserCompletely();
      });
    }
  }

  Future<void> _deleteUserCompletely() async {
    try {
      SubscriptionManager.cancelAll();
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken(true);

      if (idToken == null) {
        throw Exception("No ID token available.");
      }
      ref.invalidate(roleProvider);
      ref.invalidate(ridesHistoryProvider);
      ref.invalidate(usersDataProvider);
      ref.invalidate(authStateChangesProvider);
      ref.invalidate(firestoreServiceProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(vehiclesProvider);
      ref.invalidate(rideFlowProvider);
      ref.invalidate(rideProvider);
      ref.invalidate(ridesHistoryProvider);

      await Future.delayed(const Duration(milliseconds: 200));
      final response = await http.post(
        Uri.parse(
          'https://us-central1-one-more-tour.cloudfunctions.net/deleteUserAccount',
        ),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 && context.mounted) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => WelcomePage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error deleting account: $e")));
      }
      logger.e(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFE70137)),
            SizedBox(height: height * 0.023),
            Text(
              "Deleting your account...",
              style: GoogleFonts.cabin(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
