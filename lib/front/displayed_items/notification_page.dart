import 'package:cloud_firestore/cloud_firestore.dart';
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

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  late final String contractUrl;
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
                    bool applicationFormApproved =
                        userDoc['Application Form Verified'];
                    bool personalDetailsFormApproved =
                        userDoc['Personal & Car Details Form Verified'];
                    bool contractSigned =
                        userDoc['Contract Signing'] == 'SIGNED';
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
                    } else if (route == "/application_status" &&
                        !registrationCompleted &&
                        !applicationFormApproved) {
                      navigatorKey.currentState?.pushNamed('/application_form');
                    } else if (route == "/personalinfo_status" &&
                        !personalDetailsFormApproved &&
                        !registrationCompleted) {
                      navigatorKey.currentState?.pushNamed(
                        '/personal_data_form',
                      );
                    } else if (route == "/contract_sign" &&
                        context.mounted &&
                        !registrationCompleted &&
                        contractSigned) {
                      Navigator.of(
                        context,
                      ).push(route(title: 'Contract', url: contractUrl));
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
