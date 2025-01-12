import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsersDataProvider extends StateNotifier<Map<String, dynamic>?> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  UsersDataProvider() : super(null) {
    _fetchData();
  }

  void _fetchData() {
    if (userId != null) {
      _firestore
          .collection('Users')
          .doc(userId)
          .snapshots(includeMetadataChanges: true)
          .listen((snapshot) {
            if (snapshot.exists) {
              state = snapshot.data();
            } else {
              state = null;
            }
          });
    }
  }
}

final usersDataProvider =
    StateNotifierProvider<UsersDataProvider, Map<String, dynamic>?>((ref) {
      return UsersDataProvider();
    });
