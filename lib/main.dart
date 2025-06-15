import 'package:connectivity_plus/connectivity_plus.dart';
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

final navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi.instance.initializeTimeZone();
  bg.BackgroundGeolocation.registerHeadlessTask(headlessTask);
  WakelockPlus.enable();

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

  Future<void> _loadData() async {
    final firebaseInitFuture = FirebaseApi.instance.initialize(ref);
    final autoInitFuture = FirebaseMessaging.instance.setAutoInitEnabled(true);
    FirebaseAnalytics.instance;

    await Future.wait([
      firebaseInitFuture,
      autoInitFuture,
      Future.delayed(const Duration(seconds: 3)),
    ]);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userID = user.uid;
      FirebaseApi.instance.saveFCMToken(userID);
    }

    FlutterNativeSplash.remove();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = !connectivityResult.contains(ConnectivityResult.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightMode,
      darkTheme: darkMode,

      home: _isConnected ? WaitingPage() : NoInternetPage(),

      routes: {
        '/waiting_screen': (context) => WaitingPage(),
        '/no_internet_screen': (context) => NoInternetPage(),
        '/application_form': (context) => ApplicationForm(),
        '/personal_data_form': (context) => PersonalDataForm(),
        '/car_details': (context) => CarDetailsSwitcher(),
        '/auth_email': (context) => AuthEmail(),
        '/notification_screen':
            (context) => BlocProvider(
              create:
                  (context) => NotificationBloc()..add(FetchNotifications()),
              child: NotificationPage(),
            ),
        '/home_page': (context) => HomePage(),
        '/chat_page': (context) {
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
