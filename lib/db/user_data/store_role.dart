import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoleDataProvider extends StateNotifier<Map<String, dynamic>?> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser;
  StreamSubscription<DocumentSnapshot>? _roleSubscription;

  RoleDataProvider(this._currentUser) : super(null) {
    if (_currentUser != null) {
      _listenToRoleUpdates();
    }
  }

  void _listenToRoleUpdates() {
    _roleSubscription?.cancel();
    _roleSubscription = _firestore
        .collection('Users')
        .doc(_currentUser!.uid)
        .snapshots()
        .listen(
          (snapshot) {
            final newData = snapshot.data();

            if (newData != null &&
                newData.containsKey('Role') &&
                FirebaseAuth.instance.currentUser != null) {
              state = {
                "Role": newData['Role'],
                "isRegistered": newData['Registration Completed'] ?? false,
              };
            } else {
              state = null;
            }
          },
          onError: (error) {
            state = null;
          },
        );
  }

  @override
  void dispose() {
    _roleSubscription?.cancel();
    super.dispose();
  }
}

final roleProvider =
    AutoDisposeStateNotifierProvider<RoleDataProvider, Map<String, dynamic>?>((
      ref,
    ) {
      final userAsync = ref.watch(authStateChangesProvider);
      final user = userAsync.asData?.value;
      return RoleDataProvider(user);
    });

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
