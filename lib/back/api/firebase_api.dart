import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await FirebaseApi.instance.initializeNotifications();
  await FirebaseApi.instance.handleMessage(message);

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
    logger.d("Saved notification in background: ${message.messageId}");
  } catch (e) {
    logger.e("Error saving notification locally: $e");
  }
}

class FirebaseApi {
  FirebaseApi._();
  static final FirebaseApi instance = FirebaseApi._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final userID = FirebaseAuth.instance.currentUser?.uid;

    await _requestNotificationPermissions();
    await initializeNotifications();
    if (userID != null) {
      await saveFCMToken(userID);
      _setupTokenRefresh(userID);
    }
    await _setupMessageHandlers();
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

  void _setupTokenRefresh(String userId) {
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
          _handleNotificationTap(details.payload!);
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
        return; // Avoid duplicates
      }

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
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

  void _handleNotificationTap(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String? type = data['type'];

      if (type == 'chat') {
        navigatorKey.currentState?.pushNamed('/chat', arguments: data);
      } else {
        navigatorKey.currentState?.pushNamed('/notification_screen');
      }
    } catch (e) {
      logger.e("Error handling notification tap: $e");
    }
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) async {
      await handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      _handleNotificationTap(jsonEncode(message.data));
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(jsonEncode(initialMessage.data));
    }
  }

  Future<List<Map<String, dynamic>>> getSavedNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? messagesString = prefs.getString('notification_messages');
    return messagesString != null
        ? List<Map<String, dynamic>>.from(jsonDecode(messagesString))
        : [];
  }
}
