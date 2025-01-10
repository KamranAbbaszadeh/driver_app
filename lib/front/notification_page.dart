import 'package:driver_app/back/bloc/notification_bloc.dart';
import 'package:driver_app/back/bloc/notification_event.dart';
import 'package:driver_app/back/bloc/notification_state.dart';
import 'package:driver_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
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
                  onTap: () {
                    context.read<NotificationBloc>().add(
                      MarkMessageAsViewed(index),
                    );

                    navigatorKey.currentState?.pushNamed(route);
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.45,
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
                              width: width * 0.8,
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
