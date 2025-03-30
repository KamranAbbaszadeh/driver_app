import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    : super(RideFlowState(startRide: false, finishRide: false));

  void setStartRide(bool value) => state = state.copyWith(startRide: value);
  void setFinishRide(bool value) => state = state.copyWith(finishRide: value);
  void resetAll() => state = RideFlowState(startRide: false, finishRide: false);
}
