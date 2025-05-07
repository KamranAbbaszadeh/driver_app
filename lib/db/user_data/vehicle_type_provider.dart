import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final vehicleTypeProvider = StreamProvider<List<String>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return Stream.value([]);
  }

  final docStream =
      FirebaseFirestore.instance.collection('Users').doc(userId).snapshots();

  return docStream.map((snapshot) {
    final data = snapshot.data();
    if (data == null || !data.containsKey('Vehicle Type')) return [];

    final vehicleTypeField = data['Vehicle Type'];
    if (vehicleTypeField is String) {
      return vehicleTypeField.split(',').map((e) => e.trim()).toList();
    } else if (vehicleTypeField is List) {
      return List<String>.from(vehicleTypeField);
    } else {
      return [];
    }
  });
});
