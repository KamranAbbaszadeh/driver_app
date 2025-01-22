import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a StateProvider for the selected index
final selectedIndexProvider = StateProvider<int>((ref) => 0);
