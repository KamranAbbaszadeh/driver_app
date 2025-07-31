import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageListProvider = StreamProvider<List<dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection("Details")
      .doc('Language List')
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        if (data == null || data['Language Spoken'] == null) return [];
        final List<dynamic> languageList = data['Language Spoken'];
        return languageList;
      });
});
