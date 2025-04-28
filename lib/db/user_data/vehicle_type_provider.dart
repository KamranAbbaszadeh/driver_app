import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final vehicleTypeProvider = FutureProvider<List<String>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final doc =
      await FirebaseFirestore.instance.collection('Users').doc(userId).get();
  final data = doc.data();

  if (data == null || !data.containsKey('Vehicle Type')) return [];

  final vehicleTypeField = data['Vehicle Type'];
  if (vehicleTypeField is String) {
    return vehicleTypeField.split(',').map((e) => e.trim()).toList();
  } else {
    return [];
  }
});
