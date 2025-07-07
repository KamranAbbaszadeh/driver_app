// Main entry point of the Driver App.
// Initializes Firebase, Background Geolocation, Notifications, Badge control, and Theme setup.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/bloc/notification_bloc.dart';
import 'package:onemoretour/back/bloc/notification_event.dart';
import 'package:onemoretour/back/map_and_location/get_functions.dart';
import 'package:onemoretour/back/ride/ride_state.dart';
import 'package:onemoretour/front/auth/forms/application_forms/application_form.dart';
import 'package:onemoretour/front/auth/auth_methods/auth_email.dart';
import 'package:onemoretour/front/auth/forms/application_forms/car_details_switcher.dart';
import 'package:onemoretour/front/auth/forms/application_forms/personal_data_form.dart';
import 'package:onemoretour/front/auth/waiting_page.dart';
import 'package:onemoretour/front/displayed_items/chat_page.dart';
import 'package:onemoretour/front/displayed_items/home_page.dart';
import 'package:onemoretour/front/displayed_items/no_internet_page.dart';
import 'package:onemoretour/front/displayed_items/notification_page.dart';
import 'package:onemoretour/front/tools/theme/theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'firebase_options.dart';

// Global navigator key used for navigation from non-widget classes.
final navigatorKey = GlobalKey<NavigatorState>();

// Ensures necessary services are initialized before app runs.
void main() async {
  // Ensures Flutter binding is initialized (needed before using native plugins).
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keeps the splash screen visible until initialization is complete.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Enables immersive full-screen mode with system overlays.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initializes Firebase with platform-specific options.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi.instance.initializeTimeZone();
  // Registers background task for geolocation when app is terminated.
  bg.BackgroundGeolocation.registerHeadlessTask(headlessTask);
  // Clears app notification badge when app starts.
  FlutterAppBadgeControl.removeBadge();
  // Prevents screen from sleeping while app is running.
  WakelockPlus.enable();

  // Runs the root of the widget tree with BLoC and Riverpod providers.
  runApp(
    BlocProvider(
      create: (context) => NotificationBloc()..add(FetchNotifications()),
      child: Builder(
        builder:
            (context) => ProviderScope(
              overrides: [appContextProvider.overrideWithValue(context)],
              child: MyApp(),
            ),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _checkConnection();
    });
  }

  // Initializes Firebase Messaging, Analytics and removes splash after delay.
  Future<void> _loadData() async {
    final firebaseInitFuture = FirebaseApi.instance.initialize(ref);
    final autoInitFuture = FirebaseMessaging.instance.setAutoInitEnabled(true);
    FirebaseAnalytics.instance;

    await Future.wait([
      firebaseInitFuture,
      autoInitFuture,
      Future.delayed(const Duration(seconds: 3)),
    ]);
    // Checks if a user is signed in and saves their FCM token.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userID = user.uid;
      try {
        FirebaseApi.instance.saveFCMToken(userID);
      } on Exception catch (e) {
        logger.e(e);
      }
    }

    FlutterNativeSplash.remove();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    // Updates connection status based on current connectivity.
    setState(() {
      _isConnected = !connectivityResult.contains(ConnectivityResult.none);
    });
  }

  // Builds the main MaterialApp with theme and route configuration.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightMode,
      darkTheme: darkMode,

      // Conditional display of splash or no-internet screen based on connectivity.
      home: _isConnected ? WaitingPage() : NoInternetPage(),

      routes: {
        // Route to waiting screen
        '/waiting_screen': (context) => WaitingPage(),
        // Route to no internet screen
        '/no_internet_screen': (context) => NoInternetPage(),
        // Route to application form
        '/application_form': (context) => ApplicationForm(),
        // Route to personal data form
        '/personal_data_form': (context) => PersonalDataForm(),
        // Route to car details switcher
        '/car_details': (context) => CarDetailsSwitcher(),
        // Route to email authentication
        '/auth_email': (context) => AuthEmail(),
        // Route to notification screen with bloc provider
        '/notification_screen':
            (context) => BlocProvider(
              create:
                  (context) => NotificationBloc()..add(FetchNotifications()),
              child: NotificationPage(),
            ),
        // Route to home page
        '/home_page': (context) => HomePage(),
        // Route to chat page
        '/chat_page': (context) {
          // Extracts arguments to pass to ChatPage for correct tour and layout.
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;

          return ChatPage(
            tourId: args['tourId'] ?? '',
            width: args['width'] ?? 0.0,
            height: args['height'] ?? 0.0,
          );
        },
      },
      navigatorKey: navigatorKey,
    );
  }
}
