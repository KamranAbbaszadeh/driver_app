// Notification page showing all app notifications stored locally or retrieved from state.
// Supports marking messages as read, deleting all notifications, and routing to appropriate screens.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:onemoretour/back/bloc/notification_bloc.dart';
import 'package:onemoretour/back/bloc/notification_event.dart';
import 'package:onemoretour/back/bloc/notification_state.dart';
import 'package:onemoretour/front/tools/bottom_bar_provider.dart';
import 'package:onemoretour/front/tools/notification_notifier.dart';
import 'package:onemoretour/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A screen that displays a list of notifications for the user.
/// Supports message tap handling, badge updates, and smart redirection based on message content.
class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  late final String contractUrl;

  /// Loads the user's contract URL from Firestore if it exists.
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    FirebaseFirestore.instance.collection('Users').doc(user.uid).get().then((
      doc,
    ) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('ContractLink')) {
          return;
        }
        contractUrl = doc['ContractLink'] ?? '';
      } else {
        contractUrl = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      // Top app bar with page title, delete and mark-all-as-read actions.
      appBar: AppBar(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: width * 0.063,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          hoverColor: Colors.transparent,
          icon: Icon(
            Icons.arrow_circle_left_rounded,
            size: width * 0.1,
            color: Colors.grey.shade400,
          ),
        ),
        actions: [
          // Delete or mark all notifications as viewed.
          IconButton(
            hoverColor: Colors.transparent,
            icon: Icon(
              Icons.delete,
              size: width * 0.07,
              color: Colors.grey.shade400,
            ),
            onPressed: () {
              context.read<NotificationBloc>().add(DeleteNotifications());
            },
          ),
          // Delete or mark all notifications as viewed.
          IconButton(
            hoverColor: Colors.transparent,
            icon: Icon(
              Icons.done_all,
              size: width * 0.07,
              color: Colors.grey.shade400,
            ),
            onPressed: () {
              context.read<NotificationBloc>().add(MarkAllAsViewed());
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.watch(notificationsProvider.notifier).refresh();
              });
              FlutterAppBadgeControl.removeBadge();
            },
          ),
        ],
      ),
      // Displays loading, error, or a list of notifications based on Bloc state.
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationError) {
            return Center(child: Text("Error to load notifications"));
          } else if (state is NotificationLoaded) {
            if (state.messages.isEmpty) {
              return const Center(child: Text('No notifications available'));
            }

            return ListView.builder(
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final isViewed = state.messages[index]['isViewed'];
                final message = state.messages[index]['message'];
                final title = message['notification']['title'] ?? '';
                final route = message['data']['route'];
                final fullBody = message['data']['fullBody'];
                // Handle tap: update shared prefs, mark as viewed, update badge and navigate accordingly.
                return GestureDetector(
                  onTap: () async {
                    context.read<NotificationBloc>().add(
                      MarkMessageAsViewed(index),
                    );
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    String? messagesString = prefs.getString(
                      'notification_messages',
                    );
                    List<dynamic> messages =
                        messagesString != null
                            ? jsonDecode(messagesString)
                            : [];
                    if (messages.length > index) {
                      messages[index]['isViewed'] = true;
                      await prefs.setString(
                        'notification_messages',
                        jsonEncode(messages),
                      );
                    }
                    final unreadCount =
                        messages.where((m) => !m['isViewed']).length;
                    if (unreadCount > 0) {
                      FlutterAppBadgeControl.updateBadgeCount(unreadCount);
                    } else {
                      FlutterAppBadgeControl.removeBadge();
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(notificationsProvider.notifier).refresh();
                    });

                    String userId =
                        FirebaseAuth.instance.currentUser?.uid ?? '';
                    if (userId.isEmpty) return;

                    DocumentSnapshot userDoc =
                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(userId)
                            .get();

                    bool registrationCompleted =
                        userDoc['Registration Completed'];
                    bool applicationFormApproved =
                        userDoc['Application Form Verified'];
                    bool personalDetailsFormApproved =
                        userDoc['Personal & Car Details Form Verified'];
                    bool contractSigned =
                        userDoc['Contract Signing'] == 'SIGNED';
                    // Navigate to the appropriate screen based on message route.
                    if (route == "/chat_page") {
                      final tourId = message['data']['tourId'];
                      navigatorKey.currentState?.pushNamed(
                        '/chat_page',
                        arguments: {
                          'tourId': tourId,
                          'width': width,
                          'height': height,
                        },
                      );
                      // Navigate to the appropriate screen based on message route.
                    } else if (route == "/tour_list") {
                      ref.read(selectedIndexProvider.notifier).state = 1;
                      navigatorKey.currentState?.pop();
                      // Navigate to the appropriate screen based on message route.
                    } else if (route == "/application_status" &&
                        !registrationCompleted &&
                        !applicationFormApproved) {
                      navigatorKey.currentState?.pushNamed('/application_form');
                      // Navigate to the appropriate screen based on message route.
                    } else if (route == "/personalinfo_status" &&
                        !personalDetailsFormApproved &&
                        !registrationCompleted) {
                      navigatorKey.currentState?.pushNamed(
                        '/personal_data_form',
                      );
                      // Navigate to the appropriate screen based on message route.
                    } else if (route == "/contract_sign" &&
                        context.mounted &&
                        !registrationCompleted &&
                        contractSigned) {
                      Navigator.of(
                        context,
                      ).push(route(title: 'Contract', url: contractUrl));
                    } else {
                      navigatorKey.currentState?.pop();
                    }
                  },
                  // Notification tile with title, body, and unread dot indicator.
                  child: Container(
                    padding: EdgeInsets.all(width * 0.025),
                    margin: EdgeInsets.all(width * 0.025),
                    width: width,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width * 0.025),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: width * 0.85,

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title ?? '',
                                softWrap: true,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.045,
                                  color:
                                      isViewed
                                          ? Colors.grey
                                          : Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color!,
                                ),
                              ),
                              SizedBox(height: height * 0.005),
                              SizedBox(
                                width: width * 0.885,
                                child: Text(
                                  fullBody ?? '',
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                    color:
                                        isViewed
                                            ? Colors.grey
                                            : Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Blue dot shown only for unread messages.
                        isViewed
                            ? const SizedBox.shrink()
                            : Padding(
                              padding: EdgeInsets.only(top: height * 0.009),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                                width: width * 0.012,
                                height: height * 0.005,
                              ),
                            ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
