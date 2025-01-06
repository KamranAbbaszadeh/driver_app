import 'dart:convert';

import 'package:driver_app/back/api/get_stored_message.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>>? messages;
  String? role;
  bool isLoading = true;
  String? errorMessage;
  bool isAllViewed = false;
  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      messages = await getStoredMessages();
      setState(() {
        isAllViewed = messages!.every((message) => message['isViewed'] == true);
      });
    } catch (e) {
      errorMessage = 'Error loading data';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_messages');
    setState(() {
      messages = [];
    });
  }

  Future<void> markAllAsViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesString = prefs.getString('notification_messages');
    final messagesList =
        messagesString != null
            ? (jsonDecode(messagesString) as List)
                .map((message) => Map<String, dynamic>.from(message))
                .toList()
            : [];
    for (int i = 0; i < messagesList.length; i++) {
      messagesList[i]['isViewed'] = true;
    }
    await prefs.setString('notification_messages', jsonEncode(messagesList));
    setState(() {
      messages =
          messagesList
              .map((message) => Map<String, dynamic>.from(message))
              .toList();
    });
    isAllViewed = true;
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    //final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    if (isLoading) {
      return Scaffold(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: darkMode ? Colors.black : Colors.white,
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
          title: const Text(
            'Notifications',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {},
              hoverColor: Colors.transparent,
              icon: Icon(
                Icons.delete,
                size: width * 0.07,
                color: Colors.grey.shade400,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.done_all,
                size: width * 0.07,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),

        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: darkMode ? Colors.black : Colors.white,
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
          title: const Text(
            'Notifications',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {},
              hoverColor: Colors.transparent,
              icon: Icon(
                Icons.delete,
                size: width * 0.07,
                color: Colors.grey.shade400,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.done_all,
                size: width * 0.07,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),

        body: Center(child: Text(errorMessage!)),
      );
    }

    if (messages == null || messages!.isEmpty) {
      return Scaffold(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: darkMode ? Colors.black : Colors.white,
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
          title: const Text(
            'Notifications',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {},
              hoverColor: Colors.transparent,
              icon: Icon(
                Icons.delete,
                size: width * 0.07,
                color: Colors.grey.shade400,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.done_all,
                size: width * 0.07,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),

        body: const Center(child: Text('No messages available')),
      );
    }

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: darkMode ? Colors.black : Colors.white,
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
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await deleteNotifications();
            },
            hoverColor: Colors.transparent,
            icon: Icon(
              Icons.delete,
              size: width * 0.07,
              color: Colors.grey.shade400,
            ),
          ),
          IconButton(
            onPressed: () async {
              isAllViewed ? null : await markAllAsViewed();
            },
            icon: Icon(
              Icons.done_all,
              size: width * 0.07,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getStoredMessages(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading messages'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notification available'));
          } else {
            final messages = snapshot.data!;
            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final messageData = messages[index]['message'];
                final isViewed = messages[index]['isViewed'];
                final message = RemoteMessage.fromMap(messageData);
                final notification = message.notification;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      markMessageAsViewed(index);
                    });
                    navigatorKey.currentState?.pushNamed(message.data["route"]);
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
                              notification?.title ?? '',
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
                                message.data["fullBody"] ?? '',
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
        },
      ),
    );
  }
}
