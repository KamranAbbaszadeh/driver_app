import 'package:flutter_riverpod/flutter_riverpod.dart';

// Defines a StateProvider for the selected index
final selectedIndexProvider = StateProvider<int>((ref) => 0);
