// Manages fetching and streaming user-related data from Firestore for the current Firebase user.
// Includes user profile and approved vehicles, using Riverpod for reactive state management.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A StateNotifier that listens to the current user's document in Firestore.
/// Automatically updates the state when the user document changes in real-time.
class UsersDataProvider extends StateNotifier<Map<String, dynamic>?> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId;

  UsersDataProvider({required this.userId}) : super(null) {
    _fetchData();
  }

  /// Subscribes to changes in the 'Users' collection document for the current user.
  /// Updates state whenever Firestore sends a new snapshot.
  void _fetchData() {
    if (userId != null) {
      _firestore
          .collection('Users')
          .doc(userId)
          .snapshots(includeMetadataChanges: true)
          .listen((snapshot) {
            if (!mounted) return;
            if (snapshot.exists && mounted) {
              state = snapshot.data();
            } else {
              state = null;
            }
          });
    }
  }
}

/// Riverpod provider that exposes the current user's Firestore document as state.
/// Depends on [authStateProvider] for user identification.
final usersDataProvider =
    StateNotifierProvider<UsersDataProvider, Map<String, dynamic>?>((ref) {
      final user = ref.watch(authStateProvider).asData?.value;
      return UsersDataProvider(userId: user?.uid);
    });

/// Provides a stream of the current authentication state from FirebaseAuth.
/// Emits [User] or null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Stream provider that returns a list of approved vehicles for the current user.
/// Each vehicle contains its document ID, registration number, and type.
final vehiclesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  final userId = user?.uid;
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('Vehicles')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .where((doc) => doc.data()['isApproved'] == true)
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'registration': data['Vehicle Registration Number'] ?? doc.id,
                'vehicleType': data['Vehicle\'s Type'] ?? 'Unknown',
              };
            })
            .toList();
      });
});
