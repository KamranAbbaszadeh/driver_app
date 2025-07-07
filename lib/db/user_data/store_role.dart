// Provides a Riverpod StateNotifier to manage and listen to user role and registration status.
// Listens to real-time Firestore document snapshots for the current user and updates state accordingly.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../back/tools/subscription_manager.dart';

/// A StateNotifier that listens for changes in the current user's role and registration status.
/// Emits a map with 'Role' and 'isRegistered' keys or null if data is missing or an error occurs.
class RoleDataProvider extends StateNotifier<Map<String, dynamic>?> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser;
  StreamSubscription<DocumentSnapshot>? _roleSubscription;

  RoleDataProvider(this._currentUser) : super(null) {
    if (_currentUser != null) {
      _listenToRoleUpdates();
    }
  }

  /// Subscribes to Firestore 'Users' document snapshots for the current user.
  /// Updates the state when 'Role' or 'Registration Completed' fields change.
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
    SubscriptionManager.add(_roleSubscription!);
  }

  /// Cancels the Firestore subscription and disposes of the notifier.
  @override
  void dispose() {
    _roleSubscription?.cancel();
    super.dispose();
  }
}

/// Provides the [RoleDataProvider] as an AutoDispose Riverpod provider.
/// Watches FirebaseAuth user changes to update the role accordingly.
final roleProvider =
    AutoDisposeStateNotifierProvider<RoleDataProvider, Map<String, dynamic>?>((
      ref,
    ) {
      final userAsync = ref.watch(authStateChangesProvider);
      final user = userAsync.asData?.value;
      return RoleDataProvider(user);
    });

/// Provides a stream of authentication state changes from FirebaseAuth.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
