import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/front/tools/notification_notifier.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

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
    await initializeNotifications();
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

  Future<void> initializeNotifications() async {
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
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final Map<String, dynamic> data = jsonDecode(details.payload!);
          final String? type = data['route'];
          if (type == 'chat') {
            navigatorKey.currentState?.pushNamed(
              '/notification_page',
              arguments: details,
            );
          } else {
            navigatorKey.currentState?.pushNamed(type!);
          }
        }
      },
    );

    isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> handleMessage(RemoteMessage message) async {
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

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        if (message.data['route'] == 'chat') {
          String? tourId = message.data['body'];
          if (tourId != null) {
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

  void _handleNotificationTap(RemoteMessage message) async {
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

      final String? type = data['route'];

      if (type == 'chat') {
        String? tourId = data['body'];
        if (tourId != null) {
          String? tourName = await _fetchTourName(tourId);
          if (tourName != null) {
            navigatorKey.currentState?.pushNamed(
              '/chat_page',
              arguments: {'tourName': tourName, 'latestMessage': data['name']},
            );
          }
        }
      } else {
        navigatorKey.currentState?.pushNamed('/notification_screen');
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
        _handleNotificationTap(message);
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

      String? role = userDoc['role'];
      String collectionName = role == 'Guide' ? 'Guide' : 'Cars';

      DocumentSnapshot tourDoc =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(tourId)
              .get();

      return tourDoc.exists ? tourDoc['tourName'] : null;
    } catch (e) {
      logger.e("Error fetching tour name: $e");
      return null;
    }
  }
}
