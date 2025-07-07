// Riverpod state provider to track whether the user profile is currently being deleted.
// Used to show loading indicators or disable UI during deletion processes.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the state of profile deletion.
/// Set to `true` during deletion requests to show loading UI or prevent interactions.
final isDeletingProfileProvider = StateProvider<bool>((ref) => false);