import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/chat/message_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  final String tourId;
  final double width;
  final double height;
  const ChatPage({
    super.key,
    required this.tourId,
    required this.width,
    required this.height,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late MessageProvider _messageProvider;
  String tourName = '';

  @override
  void initState() {
    super.initState();
    _messageProvider = MessageProvider(tourId: widget.tourId);
    getTourName();
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _messageProvider.sendMessage(_messageController.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void getTourName() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      final uid = user.uid;
      final doc =
          await FirebaseFirestore.instance.collection('Users').doc(uid).get();

      String role = doc['Role'];
      String collection = role == 'Guide' ? 'Guide' : 'Cars';

      final FirebaseFirestore storage = FirebaseFirestore.instance;
      final ref = storage.collection(collection).doc(widget.tourId);
      String tourNameRaw = await ref.get().then((DocumentSnapshot doc) {
        return doc['TourName'];
      });

      setState(() {
        tourName = tourNameRaw;
      });
    }
  }

  String _formatDate(DateTime date) {
    if (date.day == DateTime.now().day) {
      return 'Today';
    }
    if (date.day == DateTime.now().subtract(Duration(days: 1)).day) {
      return 'Yesterday';
    }

    return "${date.day}/${date.month}/${date.year}";
  }

  Map<String, List<Map<String, dynamic>>> _groupMessagesByDate(
    List<Map<String, dynamic>> messages,
  ) {
    Map<String, List<Map<String, dynamic>>> groupedMessages = {};

    for (var message in messages) {
      DateTime messageDate = message['createdAt'].toDate();
      String formattedDate = _formatDate(messageDate);

      if (!groupedMessages.containsKey(formattedDate)) {
        groupedMessages[formattedDate] = [];
      }

      groupedMessages[formattedDate]!.add(message);
    }

    return groupedMessages;
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;
    return Scaffold(
      backgroundColor: Colors.black,

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _messageProvider.getMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<Map<String, dynamic>> messages = snapshot.data ?? [];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          Map<String, List<Map<String, dynamic>>> groupedMessages =
              _groupMessagesByDate(messages);

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  _buildAppBar(
                    context: context,
                    width: width,
                    height: height,
                    tourName: tourName,
                  ),
                  SizedBox(height: 30),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ListView.builder(
                          itemCount: groupedMessages.length,
                          controller: _scrollController,
                          itemBuilder: (context, index) {
                            String dateKey = groupedMessages.keys.elementAt(
                              index,
                            );
                            List<Map<String, dynamic>> messageGroup =
                                groupedMessages[dateKey]!;

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    dateKey,
                                    style: GoogleFonts.cabin(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                ...messageGroup.map((message) {
                                  final bool isMe = message['isMe'];
                                  final isAdmin =
                                      message['position'] == 'Admin';
                                  final isRead = message['isRead'];
                                  return Align(
                                    alignment:
                                        isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (isMe)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              _formatTimestamp(
                                                message['createdAt'],
                                              ),
                                              style: GoogleFonts.cabin(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        Column(
                                          crossAxisAlignment:
                                              isMe
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                          children: [
                                            if (!isMe)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12.0,
                                                    ),
                                                child: Text(
                                                  "${message['name']} (${message['position']})",
                                                  style: GoogleFonts.cabin(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        isAdmin
                                                            ? const Color.fromARGB(
                                                              180,
                                                              129,
                                                              199,
                                                              132,
                                                            )
                                                            : const Color.fromARGB(
                                                              180,
                                                              158,
                                                              158,
                                                              158,
                                                            ),
                                                  ),
                                                ),
                                              ),

                                            Container(
                                              margin: EdgeInsets.symmetric(
                                                vertical: 4,
                                                horizontal: 8,
                                              ),
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color:
                                                    isMe
                                                        ? isRead
                                                            ? Color.fromARGB(
                                                              200,
                                                              52,
                                                              168,
                                                              235,
                                                            )
                                                            : const Color.fromARGB(
                                                              255,
                                                              180,
                                                              180,
                                                              180,
                                                            )
                                                        : const Color.fromARGB(
                                                          255,
                                                          224,
                                                          224,
                                                          224,
                                                        ),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  topRight: Radius.circular(12),
                                                  bottomLeft: Radius.circular(
                                                    isMe ? 12 : 2,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    isMe ? 2 : 12,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                message['message'],
                                                style: GoogleFonts.cabin(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!isMe)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: Text(
                                              _formatTimestamp(
                                                message['createdAt'],
                                              ),
                                              style: GoogleFonts.cabin(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    int hour = dateTime.hour;
    String period = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    hour = hour == 0 ? 12 : hour;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color.fromARGB(255, 213, 212, 212)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: [
          IconButton(
            icon: Transform.rotate(
              angle: 25 * (pi / 180),
              child: Icon(Icons.attach_file, color: Colors.grey[600]),
            ),
            onPressed: () {},
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextFormField(
                style: GoogleFonts.cabin(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.black,
                ),
                onEditingComplete: _sendMessage,
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Write a message',
                  hintStyle: GoogleFonts.cabin(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          IconButton(
            icon: Icon(Icons.send, color: Colors.grey[600]),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar({
    required BuildContext context,
    required double height,
    required double width,
    required String tourName,
  }) {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_ios,
          size: width * 0.05,
          color: Colors.white,
        ),
      ),
      title:
          tourName.isEmpty
              ? SpinKitThreeBounce(
                color: const Color.fromRGBO(231, 231, 231, 1),
                size: width * 0.061,
              )
              : Text(
                tourName,
                style: GoogleFonts.daysOne(
                  fontSize: width * 0.076,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      centerTitle: true,
      toolbarHeight: height * 0.07,
      actionsPadding: EdgeInsets.all(width * 0.03),
    );
  }
}
