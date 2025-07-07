// A Riverpod provider that manages the state of vehicle details as a Map.
// Useful for holding and updating vehicle registration information before submission.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider that holds a map of vehicle details such as registration, type, and images.
/// Can be used to populate forms or prepare data for API submission.
final vehicleDetailsProvider = StateProvider<Map<String, dynamic>>((ref) => {});
