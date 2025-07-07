// Riverpod StateNotifier and provider for managing the flow of a ride session.
// Tracks whether the ride has started, the guest has been picked up, and the ride has finished.
// Persists state across app launches using SharedPreferences.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final rideFlowProvider = StateNotifierProvider<RideFlowNotifier, RideFlowState>(
  (ref) {
    return RideFlowNotifier();
  },
);

/// Immutable state class representing the current ride flow.
/// Includes flags for whether the ride has started, the guest has been picked up, and the ride has finished.
class RideFlowState {
  final bool startRide;
  final bool finishRide;
  final bool pickGuest;

  RideFlowState({
    required this.startRide,
    required this.finishRide,
    required this.pickGuest,
  });

  /// Returns a copy of the current state with updated values for any provided fields.
  RideFlowState copyWith({
    bool? startRide,
    bool? finishRide,
    bool? isFinished,
    bool? pickGuest,
  }) {
    return RideFlowState(
      startRide: startRide ?? this.startRide,
      finishRide: finishRide ?? this.finishRide,
      pickGuest: pickGuest ?? this.pickGuest,
    );
  }
}

/// Notifier that manages and persists the ride flow state.
/// Loads initial state from SharedPreferences and provides setters to update individual flags.
class RideFlowNotifier extends StateNotifier<RideFlowState> {
  RideFlowNotifier()
    : super(
        RideFlowState(startRide: false, finishRide: false, pickGuest: false),
      ) {
    _loadState();
  }

  /// Loads ride state from SharedPreferences during initialization.
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getBool('startRide') ?? false;
    final finish = prefs.getBool('finishRide') ?? false;
    final pickGuest = prefs.getBool('pickGuest') ?? false;
    state = RideFlowState(
      startRide: start,
      finishRide: finish,
      pickGuest: pickGuest,
    );
  }

  /// Updates the corresponding state flag and persists the change to SharedPreferences.
  void setStartRide(bool value) async {
    state = state.copyWith(startRide: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('startRide', value);
  }

  /// Updates the corresponding state flag and persists the change to SharedPreferences.
  void setFinishRide(bool value) async {
    state = state.copyWith(finishRide: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('finishRide', value);
  }

  /// Updates the corresponding state flag and persists the change to SharedPreferences.
  void guestPickedUp(bool value) async {
    state = state.copyWith(pickGuest: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pickGuest', value);
  }

  /// Resets all ride flow flags to false and removes them from SharedPreferences.
  void resetAll() async {
    state = RideFlowState(
      startRide: false,
      finishRide: false,
      pickGuest: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('startRide');
    await prefs.remove('finishRide');
    await prefs.remove('pickGuest');
  }
}
