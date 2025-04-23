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

  RideFlowState({required this.startRide, required this.finishRide});

  RideFlowState copyWith({
    bool? startRide,
    bool? finishRide,
    bool? isFinished,
  }) {
    return RideFlowState(
      startRide: startRide ?? this.startRide,
      finishRide: finishRide ?? this.finishRide,
    );
  }
}

class RideFlowNotifier extends StateNotifier<RideFlowState> {
  RideFlowNotifier()
    : super(RideFlowState(startRide: false, finishRide: false)) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getBool('startRide') ?? false;
    final finish = prefs.getBool('finishRide') ?? false;
    state = RideFlowState(startRide: start, finishRide: finish);
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

  void resetAll() async {
    state = RideFlowState(startRide: false, finishRide: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('startRide');
    await prefs.remove('finishRide');
  }
}
