import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsersDataProvider extends StateNotifier<Map<String, dynamic>?> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId;

  UsersDataProvider({required this.userId}) : super(null) {
    _fetchData();
  }

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

final usersDataProvider =
    StateNotifierProvider<UsersDataProvider, Map<String, dynamic>?>((ref) {
      final user = ref.watch(authStateProvider).asData?.value;
      return UsersDataProvider(userId: user?.uid);
    });

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

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
