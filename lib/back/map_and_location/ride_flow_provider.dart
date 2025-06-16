import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final rideFlowProvider = StateNotifierProvider<RideFlowNotifier, RideFlowState>(
  (ref) {
    return RideFlowNotifier();
  },
);

class RideFlowState {
  final bool startRide;
  final bool finishRide;
  final bool pickGuest;

  RideFlowState({
    required this.startRide,
    required this.finishRide,
    required this.pickGuest,
  });

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

class RideFlowNotifier extends StateNotifier<RideFlowState> {
  RideFlowNotifier()
    : super(
        RideFlowState(startRide: false, finishRide: false, pickGuest: false),
      ) {
    _loadState();
  }

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

  void setStartRide(bool value) async {
    state = state.copyWith(startRide: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('startRide', value);
  }

  void setFinishRide(bool value) async {
    state = state.copyWith(finishRide: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('finishRide', value);
  }

  void guestPickedUp(bool value) async {
    state = state.copyWith(pickGuest: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pickGuest', value);
  }

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
