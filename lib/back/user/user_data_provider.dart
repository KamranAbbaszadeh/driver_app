import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/user/user_data_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel> getUserStream(String uid) {
    return _db.collection('Users').doc(uid).snapshots().map((doc) {
      return UserModel.fromMap(doc.data() ?? {});
    });
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final currentUserDataProvider = StreamProvider<UserModel>((ref) {
  final authUser = FirebaseAuth.instance.currentUser;
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (authUser == null) {
    return Stream.error('User not logged in');
  }

  return firestoreService.getUserStream(authUser.uid);
});
