import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/bloc/notification_bloc.dart';
import 'package:driver_app/back/bloc/notification_event.dart';
import 'package:driver_app/front/auth/forms/application_forms/application_form.dart';
import 'package:driver_app/front/auth/auth_methods/auth_email.dart';
import 'package:driver_app/front/auth/forms/application_forms/car_details_form.dart';
import 'package:driver_app/front/auth/forms/contracts/contract_sign_form.dart';
import 'package:driver_app/front/auth/forms/application_forms/personal_data_form.dart';
import 'package:driver_app/front/auth/waiting_page.dart';
import 'package:driver_app/front/displayed_items/chat_page.dart';
import 'package:driver_app/front/intro/introduction_screens/introduction_screen.dart';
import 'package:driver_app/front/displayed_items/home_page.dart';
import 'package:driver_app/front/displayed_items/no_internet_page.dart';
import 'package:driver_app/front/displayed_items/notification_page.dart';
import 'package:driver_app/front/tools/theme/theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

int? isViewed;
final navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
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
    _loadData();
    _checkConnection();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isViewed = prefs.getInt('IntroScreen');

    if (mounted) {
      await FirebaseApi.instance.initialize(ref);
    }

    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    FirebaseAnalytics.instance;

    await Future.delayed(const Duration(seconds: 3));
    FlutterNativeSplash.remove();

    setState(() {});
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
      home:
          _isConnected
              ? isViewed != 0
                  ? IntroductionScreen()
                  : WaitingPage()
              : NoInternetPage(),

      routes: {
        '/intro_screen': (context) => IntroductionScreen(),
        '/waiting_screen': (context) => WaitingPage(),
        '/no_internet_screen': (context) => NoInternetPage(),
        '/application_form': (context) => ApplicationForm(),
        '/personal_data_form': (context) => PersonalDataForm(),
        '/car_details': (context) => CarDetailsForm(),
        '/auth_email': (context) => AuthEmail(),
        '/notification_screen':
            (context) => BlocProvider(
              create:
                  (context) => NotificationBloc()..add(FetchNotifications()),
              child: NotificationPage(),
            ),
        '/contract_sign': (context) => ContractSignForm(),
        '/home_page': (context) => HomePage(),
        '/chat_page':
            (context) => ChatPage(tourId: 'tourId', width: 0, height: 0),
      },
      navigatorKey: navigatorKey,
    );
  }
}
