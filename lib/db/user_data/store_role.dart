import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoleDataProvider extends StateNotifier<String?> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser;

  RoleDataProvider(this._currentUser) : super(null) {
    if (_currentUser != null) {
      _listenToRoleUpdates();
    }
  }

  void _listenToRoleUpdates() {
    _firestore
        .collection('Users')
        .doc(_currentUser!.uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            final newData = snapshot.data();
            if (newData != null && newData.containsKey('Role')) {
              state = newData['Role'] as String?;
            } else {
              state = null;
            }
          },
          onError: (error) {
            state = null;
          },
        );
  }
}

final roleProvider = StateNotifierProvider<RoleDataProvider, String?>((ref) {
  final currentUser = FirebaseAuth.instance.currentUser;
  return RoleDataProvider(currentUser);
});
