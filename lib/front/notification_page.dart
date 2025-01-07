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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              context.read<NotificationBloc>().add(DeleteNotifications());
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
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
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.all(10),
                    width: width,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
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
                                fontSize: 18,
                                color:
                                    isViewed
                                        ? Colors.grey
                                        : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color!,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: width * 0.8,
                              child: Text(
                                fullBody ?? '',
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 16,
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
                              width: 5,
                              height: 5,
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
