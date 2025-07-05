import 'dart:async';

class SubscriptionManager {
  static final List<StreamSubscription> _subs = [];

  static void add(StreamSubscription sub) => _subs.add(sub);

  static Future<void> cancelAll() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }
}