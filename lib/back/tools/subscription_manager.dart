// Manages a global list of active StreamSubscriptions.
// Allows for central subscription tracking and cleanup using a singleton-style approach.
import 'dart:async';

class SubscriptionManager {
  /// A static list of all registered [StreamSubscription]s to be managed.
  static final List<StreamSubscription> _subs = [];

  /// Adds a [StreamSubscription] to the internal list for later cancellation.
  static void add(StreamSubscription sub) => _subs.add(sub);

  /// Cancels all tracked [StreamSubscription]s and clears the list.
  /// Ensures clean resource disposal when no longer needed.
  static Future<void> cancelAll() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }
}
