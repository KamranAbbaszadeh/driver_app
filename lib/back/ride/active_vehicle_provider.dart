import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeVehicleProvider = StreamProvider<String?>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.data()?['Active Vehicle'] as String?);
});

final vehicleDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final vehicleId = await ref.watch(activeVehicleProvider.future);
  if (vehicleId == null) return null;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('Vehicles')
      .doc(vehicleId)
      .get();

  return doc.data();
});
