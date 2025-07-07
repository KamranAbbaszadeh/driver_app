// A Riverpod state provider that holds the driver's current location data as a Map.
// Useful for sharing location updates across multiple widgets or services.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current location data as a map (e.g., latitude, longitude, speed).
/// Can be used across the app to access or update the user's latest known position.
final locationProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
