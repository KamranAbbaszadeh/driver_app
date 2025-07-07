// Provides a custom slide-up route transition to navigate to UrlLauncherWebView.
import 'package:flutter/material.dart';
import 'package:onemoretour/front/intro/url_launcher_web_view.dart';

/// Creates a [PageRoute] with a slide-up transition to the [UrlLauncherWebView] widget.
/// Accepts a `title` and `url` to pass into the web view.
Route route({required String title, required String url}) {
  return PageRouteBuilder(
    pageBuilder:
        (context, animation, secondaryAnimation) =>
            UrlLauncherWebView(title: title, url: url),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end);
      final offsetAnimation = animation.drive(tween);
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
