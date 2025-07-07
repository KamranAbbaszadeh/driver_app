// A simple Riverpod StateNotifier for managing a loading state.
// Used to show or hide loading indicators across the app.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A [StateNotifier] that manages a boolean loading state.
/// Call [startLoading] to set state to true, and [stopLoading] to set it to false.
class LoadingNotifier extends StateNotifier<bool> {
  LoadingNotifier() : super(false);

  void startLoading() => state = true;
  void stopLoading() => state = false;
}

/// Global provider for accessing the loading state managed by [LoadingNotifier].
/// Returns `true` when loading, and `false` otherwise.
final loadingProvider = StateNotifierProvider<LoadingNotifier, bool>((ref) {
  return LoadingNotifier();
});
