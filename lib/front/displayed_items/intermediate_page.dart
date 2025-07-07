import 'package:onemoretour/front/displayed_items/home_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';

// Displays a success animation using Lottie after an action is completed.
// Waits briefly before navigating the user to the HomePage using a fade transition.

/// A transitional page that shows a Lottie check animation after completing a task.
/// Automatically redirects to the HomePage after a short delay.
class IntermediatePage extends StatefulWidget {
  const IntermediatePage({super.key});

  @override
  State<IntermediatePage> createState() => _IntermediatePageState();
}

class _IntermediatePageState extends State<IntermediatePage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  /// Initializes the animation controller.
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  /// Disposes the animation controller to prevent memory leaks.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the theme mode to load the appropriate Lottie animation.
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: darkMode ? Color(0xFF0169AA) : Color(0xFF34A8EB),
      body: Center(
        // Load and play the Lottie animation, then navigate after a 2-second delay.
        child: Lottie.asset(
          darkMode ? 'assets/check_dark.json' : 'assets/check_light.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
            Future.delayed(Duration(seconds: 2), () {
              if (context.mounted) {
                // Navigate to HomePage after animation plays and delay completes.
                Navigator.pushAndRemoveUntil(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: const HomePage(),
                  ),
                  (route) => false,
                );
              }
            });
          },
        ),
      ),
    );
  }
}
