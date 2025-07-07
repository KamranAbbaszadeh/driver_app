// A simple Riverpod state provider for managing top padding dynamically.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider that holds the top padding value.
/// Useful for adjusting layout spacing dynamically across widgets.
final topPaddingProvider = StateProvider<double>((ref) => 0.0);
