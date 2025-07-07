// Defines the light and dark theme settings for the Driver App.
import 'package:flutter/material.dart';

/// Light theme configuration used throughout the app.
ThemeData lightMode = ThemeData(
  // Defines custom page transition animations for light mode.
  pageTransitionsTheme: PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
    },
  ),
  // Sets overall brightness to light.
  brightness: Brightness.light,
  // Defines color scheme with custom surface color for light theme.
  colorScheme: ColorScheme.light(surface: Color.fromARGB(255, 52, 168, 235)),
);

/// Dark theme configuration used throughout the app.
ThemeData darkMode = ThemeData(
  // Defines custom page transition animations for dark mode.
  pageTransitionsTheme: PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
    },
  ),
  // Sets overall brightness to dark.
  brightness: Brightness.dark,
  // Defines color scheme with custom surface color for dark theme.
  colorScheme: ColorScheme.dark(surface: Color.fromARGB(255, 1, 105, 170)),
);
