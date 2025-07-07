// Provides Firestore service and Riverpod providers to manage user data streams.
// Includes a service class to fetch user data and providers to expose real-time user data to the app.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/user/user_data_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service class to interact with Firestore for user data operations.
/// Provides a stream of [UserModel] for the given user ID.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns a stream of [UserModel] by listening to Firestore document snapshots.
  /// Converts Firestore data to [UserModel] objects.
  Stream<UserModel> getUserStream(String uid) {
    return _db.collection('Users').doc(uid).snapshots().map((doc) {
      return UserModel.fromMap(doc.data() ?? {});
    });
  }
}

/// Riverpod provider to expose a singleton instance of [FirestoreService].
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Riverpod stream provider that emits the current authenticated user's [UserModel].
/// Emits an error if no user is logged in.
final currentUserDataProvider = StreamProvider<UserModel>((ref) {
  final authUser = FirebaseAuth.instance.currentUser;
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (authUser == null) {
    return Stream.error('User not logged in');
  }

  return firestoreService.getUserStream(authUser.uid);
});
