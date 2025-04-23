import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/rides_history/ride_history_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RidesHistoryState {
  final List<RideHistory> allRides;
  final List<RideHistory> filteredRides;
  final int? price;
  final bool? isPaid;

  RidesHistoryState({
    this.allRides = const [],
    this.filteredRides = const [],
    this.price = 0,
    this.isPaid = false,
  });

  RidesHistoryState copyWith({
    List<RideHistory>? allRides,
    List<RideHistory>? filteredRides,
    int? price,
    bool? isPaid,
  }) {
    return RidesHistoryState(
      allRides: allRides ?? this.allRides,
      filteredRides: filteredRides ?? this.filteredRides,
      price: price ?? this.price,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

class RidesHistoryNotifier extends StateNotifier<RidesHistoryState> {
  RidesHistoryNotifier() : super(RidesHistoryState()) {
    _fetchData();
  }

  bool _mounted = true;
  StreamSubscription<QuerySnapshot>? carsSubscription;
  StreamSubscription<QuerySnapshot>? guideSubscription;

  Future<void> _fetchData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    carsSubscription = FirebaseFirestore.instance
        .collection('Cars')
        .snapshots()
        .listen(
          (snapshot) {
            final currentRides = {
              for (var r in state.allRides.where((r) => r.driver == userId))
                r.docId: r,
            };
            for (var doc in snapshot.docs) {
              final ride = RideHistory.fromFirestore(
                data: doc.data(),
                id: doc.id,
              );
              if (ride.driver == userId) {
                currentRides[ride.docId] = ride;
              }
            }
            final allRides = currentRides.values.toList();

            final filtered =
                allRides.where((ride) => ride.isCompleted == true).toList()
                  ..sort((a, b) => b.startDate.compareTo(a.startDate));

            if (_mounted) {
              state = state.copyWith(
                allRides: allRides,
                filteredRides: filtered,
              );
            }
          },
          onError: (error) {
            // Handle error if needed
          },
        );

    guideSubscription = FirebaseFirestore.instance
        .collection('Guide')
        .snapshots()
        .listen(
          (snapshot) {
            final currentRides = {for (var r in state.allRides) r.docId: r};
            for (var doc in snapshot.docs) {
              final ride = RideHistory.fromFirestore(
                data: doc.data(),
                id: doc.id,
              );
              if (ride.guide == userId) {
                currentRides[ride.docId] = ride;
              }
            }
            final allCombined = currentRides.values.toList();

            final filtered =
                allCombined.where((ride) => ride.isCompleted == true).toList()
                  ..sort((a, b) => b.startDate.compareTo(a.startDate));

            if (_mounted) {
              state = state.copyWith(
                allRides: allCombined,
                filteredRides: filtered,
              );
            }
          },
          onError: (error) {
            // Handle error if needed
          },
        );
  }

  int get nonCompletedRidesCount => state.allRides.length;

  int get completedRidesCount => state.filteredRides.length;
  double get totalCompletedEarnings =>
      state.allRides.fold(0.0, (calc, ride) => calc + ride.price);
  Map<String, Map<bool, double>> get earningsByDate {
    final map = <String, Map<bool, double>>{};

    for (var ride in state.filteredRides) {
      final dateKey =
          "${ride.startDate.year}-${ride.startDate.month.toString().padLeft(2, '0')}-${ride.startDate.day.toString().padLeft(2, '0')}";

      map.putIfAbsent(dateKey, () => {true: 0.0, false: 0.0});
      map[dateKey]![ride.isPaid] = map[dateKey]![ride.isPaid]! + ride.price;
    }

    return map;
  }

  @override
  void dispose() {
    _mounted = false;
    carsSubscription?.cancel();
    guideSubscription?.cancel();
    super.dispose();
  }
}

final ridesHistoryProvider =
    StateNotifierProvider<RidesHistoryNotifier, RidesHistoryState>((ref) {
      return RidesHistoryNotifier();
    });
