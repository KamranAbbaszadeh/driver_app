// Riverpod providers for accessing the driver's active vehicle data.
// Includes a stream provider for the active vehicle ID and a future provider for the full vehicle document.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watches the current user's Firestore document for changes to the 'Active Vehicle' field.
/// Emits the vehicle ID as a string or null if not found or the user is not logged in.
final activeVehicleProvider = StreamProvider<String?>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.data()?['Active Vehicle'] as String?);
});

/// Fetches the full vehicle document from the user's 'Vehicles' subcollection
/// based on the currently active vehicle ID.
/// Returns a map of vehicle data or null if not found.
final vehicleDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final vehicleId = await ref.watch(activeVehicleProvider.future);
  if (vehicleId == null) return null;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;

  final doc =
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Vehicles')
          .doc(vehicleId)
          .get();

  return doc.data();
});
