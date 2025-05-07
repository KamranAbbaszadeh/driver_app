import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:driver_app/front/tools/bottom_bar_provider.dart';
import 'package:driver_app/front/tools/notification_notifier.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final Logger logger = Logger();

String? currentChatTourId;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? messagesString = prefs.getString('notification_messages');
    List<dynamic> messages =
        messagesString != null ? jsonDecode(messagesString) : [];

    String? messageId = message.messageId;
    if (messageId != null && messages.any((m) => m['messageId'] == messageId)) {
      return;
    }

    messages.add({
      'message': message.toMap(),
      'isViewed': false,
      'messageId': messageId,
    });

    await prefs.setString('notification_messages', jsonEncode(messages));
  } catch (e) {
    logger.e("Error saving notification locally in background: $e");
  }
}

class FirebaseApi {
  FirebaseApi._();
  static final FirebaseApi instance = FirebaseApi._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize(WidgetRef ref) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final userID = FirebaseAuth.instance.currentUser?.uid;

    await _requestNotificationPermissions();
    await initializeNotifications(ref);
    if (userID != null) {
      await saveFCMToken(userID);
      setupTokenRefresh(userID);
    }

    await _setupMessageHandlers(ref);
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      logger.e("Error requesting notification permissions: $e");
    }
  }

  Future<void> saveFCMToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('Users').doc(userId).update(
          {'fcmToken': token},
        );
      }
    } catch (e) {
      logger.e("Error saving FCM token: $e");
    }
  }

  void setupTokenRefresh(String userId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      try {
        await FirebaseFirestore.instance.collection('Users').doc(userId).update(
          {'fcmToken': newToken},
        );
      } catch (e) {
        logger.e("Error updating refreshed FCM token: $e");
      }
    });
  }

  Future<void> initializeNotifications(WidgetRef ref) async {
    if (isFlutterLocalNotificationsInitialized) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: const DarwinInitializationSettings(),
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null) {
          final Map<String, dynamic> data = jsonDecode(details.payload!);
          final String? type = data['route'];
          if (type == '/chat_page') {
            final String? tourId = data['tourId'];
            final String? name = data['name'];
            if (tourId != null && name != null) {
              navigatorKey.currentState?.pushNamed('/notification_screen');
            }
          } else if (type == "/new_tours") {
            ref.read(selectedIndexProvider.notifier).state = 1;
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              "home_page",
              (route) => false,
            );
          } else {
            String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
            if (userId.isEmpty) return;

            DocumentSnapshot userDoc =
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .get();

            bool registrationCompleted = userDoc['Registration Completed'];
            navigatorKey.currentState?.pushNamed(
              registrationCompleted
                  ? '/home_page'
                  : type ?? '/notification_screen',
            );
          }
        }
      },
    );

    isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> handleMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification == null) {
      logger.w("⚠️ Foreground message has no notification payload.");
    }

    try {
      String? messageId = message.messageId;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? messagesString = prefs.getString('notification_messages');
      List<dynamic> messages =
          messagesString != null ? jsonDecode(messagesString) : [];

      if (messageId != null &&
          messages.any((m) => m['messageId'] == messageId)) {
        return;
      }

      if (notification != null && android != null) {
        if (message.data['route'] == '/chat_page') {
          String? tourId = message.data['tourId'];
          if (tourId != null) {
            if (currentChatTourId == tourId) {
              messages.add({
                'message': message.toMap(),
                'isViewed': true,
                'messageId': messageId,
              });
              await prefs.setString(
                'notification_messages',
                jsonEncode(messages),
              );
              return;
            }

            final lastTourId = prefs.getString('last_left_chat_tourId');
            final lastLeft = prefs.getInt('last_left_chat_time') ?? 0;
            final now = DateTime.now().millisecondsSinceEpoch;

            if (lastTourId == tourId && (now - lastLeft) < 5000) {
              return;
            }
            String? tourName = await _fetchTourName(tourId);
            if (tourName != null) {
              String notificationTitle = 'Tour: $tourName';
              String notificationBody =
                  '${message.data['name']} just sent you a message for tour $tourName';

              await _localNotifications.show(
                notification.hashCode,
                notificationTitle,
                notificationBody,
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    'high_importance_channel',
                    'High Importance Notifications',
                    channelDescription:
                        'This channel is used for important notifications',
                    importance: Importance.high,
                    icon: '@mipmap/launcher_icon',
                  ),
                  iOS: const DarwinNotificationDetails(
                    presentAlert: true,
                    presentBadge: true,
                    presentSound: true,
                  ),
                ),
                payload: jsonEncode(message.data),
              );
            }
          }
        } else {
          await _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                channelDescription:
                    'This channel is used for important notifications',
                importance: Importance.high,
                icon: '@mipmap/launcher_icon',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      }

      messages.add({
        'message': message.toMap(),
        'isViewed': false,
        'messageId': messageId,
      });
      await prefs.setString('notification_messages', jsonEncode(messages));
    } catch (e) {
      logger.e("Error handling message: $e");
    }
  }

  void _handleNotificationTap(RemoteMessage message, WidgetRef ref) async {
    try {
      String? messageId = message.messageId;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? messagesString = prefs.getString('notification_messages');
      List<dynamic> messages =
          messagesString != null ? jsonDecode(messagesString) : [];

      if (messageId != null &&
          messages.any((m) => m['messageId'] == messageId)) {
        return;
      }

      messages.add({
        'message': message.toMap(),
        'isViewed': false,
        'messageId': messageId,
      });
      await prefs.setString('notification_messages', jsonEncode(messages));

      final Map<String, dynamic> data = message.data;

      final String? route = data['route'];

      if (route == '/chat_page') {
        String? tourId = data['tourId'];
        if (tourId != null) {
          String? tourName = await _fetchTourName(tourId);
          if (tourName != null) {
            navigatorKey.currentState?.pushNamed('/notification_screen');
          }
        }
      } else if (route == "/new_tours") {
        ref.read(selectedIndexProvider.notifier).state = 1;
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          "home_page",
          (route) => false,
        );
      } else {
        navigatorKey.currentState?.pushNamed(route ?? '/notification_screen');
      }
    } catch (e) {
      logger.e("Error handling notification tap: $e");
    }
  }

  Future<void> _setupMessageHandlers(WidgetRef ref) async {
    FirebaseMessaging.onMessage.listen((message) async {
      await handleMessage(message);

      ref.read(notificationsProvider.notifier).refresh();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      try {
        _handleNotificationTap(message, ref);
      } catch (e) {
        logger.e("Error handling message opened app: $e");
      }
    });
  }

  Future<String?> _fetchTourName(String tourId) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return null;

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .get();

      String? role = userDoc['Role'];
      if (role == "Driver Cum Guide") {
        DocumentSnapshot? tourDoc;

        String collectionName = 'Guide';
        final guideDoc =
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(tourId)
                .get();

        if (guideDoc.exists) {
          tourDoc = guideDoc;
        } else {
          collectionName = 'Cars';
          final carsDoc =
              await FirebaseFirestore.instance
                  .collection(collectionName)
                  .doc(tourId)
                  .get();
          if (carsDoc.exists) {
            tourDoc = carsDoc;
          }
        }

        if (tourDoc == null) return null;
        return tourDoc['TourName'];
      } else if (role == "Driver") {
        String collectionName = 'Cars';
        final tourDoc =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .collection(collectionName)
                .doc(tourId)
                .get();

        if (!tourDoc.exists) return null;
        return tourDoc['tourName'];
      } else if (role == "Guide") {
        String collectionName = 'Guide';
        final tourDoc =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .collection(collectionName)
                .doc(tourId)
                .get();

        if (!tourDoc.exists) return null;
        return tourDoc['tourName'];
      }
    } catch (e) {
      logger.e("Error fetching tour name: $e");
      return null;
    }
    return null;
  }

  Future<void> initializeTimeZone() async {
    tz.initializeTimeZones();

    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> scheduleTourReminders(DateTime startDate, String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduled = prefs.getStringList('scheduledTours') ?? [];

    if (scheduled.contains(tourId)) return;

    scheduled.add(tourId);
    await prefs.setStringList('scheduledTours', scheduled);

    _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final detailsDoc =
        await FirebaseFirestore.instance
            .collection('Details')
            .doc('Ride')
            .get();

    final List<dynamic> periods = detailsDoc['Notification Period'] ?? [];
    final notificationTimes =
        periods.map((minutes) => Duration(minutes: minutes as int)).toList();

    int baseId = tourId.hashCode;

    for (int i = 0; i < notificationTimes.length; i++) {
      final scheduledTime = startDate.subtract(notificationTimes[i]);

      if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
        await _localNotifications.zonedSchedule(
          baseId + i,
          '⏰ Tour Reminder',
          'Tour starts in ${notificationTimes[i].inMinutes ~/ 60 > 0 ? '${notificationTimes[i].inMinutes ~/ 60} hour(s)' : '${notificationTimes[i].inMinutes} minutes'}',
          tz.TZDateTime.from(scheduledTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
                  'This channel is used for important notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
              additionalFlags: Int32List.fromList(<int>[4]),
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
      }
      logger.e("Scheduled notification for tour $tourId at $scheduledTime");
    }
  }

  void cancelTourReminders(String tourId) async {
    final baseId = tourId.hashCode;
    for (int i = 0; i < 4; i++) {
      await FlutterLocalNotificationsPlugin().cancel(baseId + i);
    }

    final prefs = await SharedPreferences.getInstance();
    final scheduled = prefs.getStringList('scheduledTours') ?? [];
    scheduled.remove(tourId);
    await prefs.setStringList('scheduledTours', scheduled);
  }

  Future<void> checkAndRequestExactAlarmPermission(BuildContext context) async {
    if (!Platform.isAndroid) return;
    final width = MediaQuery.of(context).size.width;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt < 33) return;

    final alarmManager =
        FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final canSchedule =
        await alarmManager?.canScheduleExactNotifications() ?? false;

    if (!canSchedule && context.mounted) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text(
                "Allow Exact Alarms",
                style: GoogleFonts.gothicA1(fontWeight: FontWeight.bold),
              ),
              content: Text(
                "To ensure you receive tour reminders exactly on time, "
                "please allow this app to schedule exact alarms in settings.",
                style: TextStyle(fontSize: width * 0.04),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final intent = AndroidIntent(
                      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
                    );
                    await intent.launch();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    "Open Settings",
                    style: GoogleFonts.cabin(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.cabin(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
      );
    }
  }
}
