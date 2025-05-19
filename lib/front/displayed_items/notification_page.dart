import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/bloc/notification_bloc.dart';
import 'package:driver_app/back/bloc/notification_event.dart';
import 'package:driver_app/back/bloc/notification_state.dart';
import 'package:driver_app/front/tools/bottom_bar_provider.dart';
import 'package:driver_app/front/tools/notification_notifier.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: darkMode ? Colors.black : Colors.white,
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
            },
          ),
        ],
      ),
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
                return GestureDetector(
                  onTap: () async {
                    context.read<NotificationBloc>().add(
                      MarkMessageAsViewed(index),
                    );
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
                    } else if (route == "/tour_list") {
                      ref.read(selectedIndexProvider.notifier).state = 1;
                      navigatorKey.currentState?.pop();
                    } else if (route == "/application_status") {
                      navigatorKey.currentState?.pushNamed('/application_form');
                    } else if (route == "/personalinfo_status") {
                    } else {
                      registrationCompleted
                          ? navigatorKey.currentState?.pop()
                          : navigatorKey.currentState?.pushNamed(route);
                    }
                  },
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
                        Column(
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
                        const Spacer(),
                        isViewed
                            ? const SizedBox.shrink()
                            : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                              width: width * 0.012,
                              height: height * 0.005,
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
