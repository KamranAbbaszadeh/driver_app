import 'package:onemoretour/front/displayed_items/home_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';

class IntermediatePage extends StatefulWidget {
  const IntermediatePage({super.key});

  @override
  State<IntermediatePage> createState() => _IntermediatePageState();
}

class _IntermediatePageState extends State<IntermediatePage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: darkMode ? Color(0xFF0169AA) : Color(0xFF34A8EB),
      body: Center(
        child: Lottie.asset(
          darkMode ? 'assets/check_dark.json' : 'assets/check_light.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
            Future.delayed(Duration(seconds: 2), () {
              if (context.mounted) {
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
