import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/api/firebase_api.dart';
import 'package:driver_app/back/chat/chat_service.dart';
import 'package:driver_app/back/chat/media_files_picker.dart';
import 'package:driver_app/back/chat/upload_media_files.dart';
import 'package:driver_app/back/chat/video_widget.dart';
import 'package:driver_app/back/tools/video_player_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late ScrollController _scrollController;
  String tourName = '';
  final ChatService _chatService = ChatService();
  final FirebaseAuth auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> media = [];
  String error = "No Error Detected";
  final storageRef = FirebaseStorage.instance.ref();

  @override
  void initState() {
    super.initState();
    getTourName();
    _scrollController = ScrollController();
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _chatService.sendMessage(
        message: _messageController.text,
        tourID: widget.tourId,
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void getTourName() async {
    try {
      final User? user = auth.currentUser;

      if (user != null) {
        final uid = user.uid;
        final doc =
            await FirebaseFirestore.instance.collection('Users').doc(uid).get();

        String role = doc['Role'];
        String collection = role == 'Guide' ? 'Guide' : 'Cars';

        final ref = FirebaseFirestore.instance
            .collection(collection)
            .doc(widget.tourId);
        String tourNameRaw = await ref.get().then((DocumentSnapshot doc) {
          return doc['TourName'];
        });

        setState(() {
          tourName = tourNameRaw;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error fetching tour name: $e";
      });
      logger.e('Error: $e');
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

  Widget displayMessageWithMedia(BuildContext context, String text) {
    final urlPattern =
        r'(?:(?:https?|ftp):\/\/)?(?:www\.)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\/?[^\s]*';
    final regExp = RegExp(urlPattern, caseSensitive: false);

    Iterable<Match> matches = regExp.allMatches(text);
    List<String> urls = matches.map((match) => match.group(0)!).toList();

    if (urls.isEmpty) {
      return Text(text);
    }

    String? imageUrl;
    String? videoUrl;
    String? firstUrl;
    for (var url in urls) {
      Uri? uri = Uri.tryParse(url);
      if (uri != null) {
        if (_isImageExtension(uri.path)) {
          imageUrl = url;
          break;
        } else if (_isVideoExtension(uri.path)) {
          videoUrl = url;
        } else {
          firstUrl ??= url;
        }
      }
    }

    bool isOnlyUrl = text.trim() == urls.first;

    String cleanedText = text;
    for (var url in urls) {
      cleanedText = cleanedText.replaceAll(url, "").trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isOnlyUrl && cleanedText.isNotEmpty)
          SizedBox(
            width: 200,
            child: Text(
              cleanedText,
              style: GoogleFonts.cabin(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),
        const SizedBox(height: 8),
        if (imageUrl != null)
          GestureDetector(
            onTap: () => showImageDialog(context, imageUrl!),

            child: Image.network(
              imageUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Icon(Icons.error, color: Colors.black),
            ),
          ),
        if (videoUrl != null) VideoPlayerWidget(videoUrl: Uri.parse(videoUrl)),
        if (firstUrl != null)
          InkWell(
            onTap: () async {
              String urlWithPrefix =
                  firstUrl!.startsWith('http') ? firstUrl : 'http://$firstUrl';
              Uri url = Uri.parse(urlWithPrefix);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                debugPrint("Could not launch $firstUrl");
              }
            },
            child: SizedBox(
              width: 200,
              child: Linkify(
                onOpen: (link) async {
                  Uri url = Uri.parse(link.url);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    debugPrint("Could not launch ${link.url}");
                  }
                },
                text: firstUrl,
                style: GoogleFonts.cabin(fontSize: 16, color: Colors.blue),
                softWrap: true,
              ),
            ),
          ),
      ],
    );
  }

  Widget displayContent(String text) {
    if (isUrl(text)) {
      return displayMessageWithMedia(context, text);
    }

    return SizedBox(
      width: 200,
      child: Text(
        text,
        style: GoogleFonts.cabin(fontSize: 16, color: Colors.black),
        softWrap: true,
      ),
    );
  }

  void showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  bool isUrl(String message) {
    final urlPattern =
        r'(\b(?:https?://)?[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+(?:/[\S]*)?\b)';
    final regExp = RegExp(urlPattern, caseSensitive: false);

    return regExp.hasMatch(message);
  }

  bool isImage(String message) {
    final urlPattern =
        r'(?:(?:https?|ftp):\/\/)?(?:www\.)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\/?[^\s]*';
    final regExp = RegExp(urlPattern, caseSensitive: false);

    Iterable<Match> matches = regExp.allMatches(message);

    for (var match in matches) {
      Uri? uri = Uri.tryParse(match.group(0)!);
      if (uri != null && _isImageExtension(uri.path)) {
        return true;
      }
    }
    return false;
  }

  bool isVideo(String message) {
    final urlPattern =
        r'(?:(?:https?|ftp):\/\/)?(?:www\.)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\/?[^\s]*';
    final regExp = RegExp(urlPattern, caseSensitive: false);

    Iterable<Match> matches = regExp.allMatches(message);

    for (var match in matches) {
      Uri? uri = Uri.tryParse(match.group(0)!);
      if (uri != null && _isVideoExtension(uri.path)) {
        return true;
      }
    }
    return false;
  }

  bool _isImageExtension(String path) {
    return path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.png') ||
        path.toLowerCase().endsWith('.gif');
  }

  bool _isVideoExtension(String path) {
    return path.toLowerCase().endsWith('.mp4') ||
        path.toLowerCase().endsWith('.mov') ||
        path.toLowerCase().endsWith('.avi') ||
        path.toLowerCase().endsWith('.mkv');
  }

  void updateMedia(int index, String key, dynamic value) {
    setState(() {
      media[index][key] = value;
    });
  }

  Future<void> pickFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result != null) {
      PlatformFile doc = result.files.first;
      final file = File(doc.path!);
      updateMedia(index, 'file', file);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File uploaded: ${doc.name}')));
      }
    } else if (media[index]['file'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No file selected')));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;
    final User? user = auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getMessages(tourID: widget.tourId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<Map<String, dynamic>> messages = snapshot.data ?? [];

          Map<String, List<Map<String, dynamic>>> groupedMessages =
              _groupMessagesByDate(messages);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              final currentScroll = _scrollController.position.pixels;

              if (currentScroll != maxScroll) {
                _scrollToBottom();
              }
            }
          });
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
                                  final bool isMe = message['UID'] == user!.uid;
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
                                              child: displayContent(
                                                message['message'],
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
          PopupMenuButton(
            icon: Transform.rotate(
              angle: 25 * (pi / 180),
              child: Icon(Icons.attach_file, color: Colors.grey[600]),
            ),
            color: Colors.white,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.image, color: Colors.grey[600]),
                      SizedBox(width: 10),
                      Text(
                        'Media',
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    var resultList = await mediaFilePicker();
                    try {
                      if (resultList != null && resultList.isNotEmpty) {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  backgroundColor: Colors.white,

                                  actions: [
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.cabin(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final uid =
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid;
                                        for (
                                          int i = 0;
                                          i <= resultList.length;
                                          i++
                                        ) {
                                          String uploadedUrl =
                                              await uploadMediaFile(
                                                storageRef: storageRef,
                                                userID: uid,
                                                file: resultList[i],
                                                folderName: 'Chat',
                                                tourId: widget.tourId,
                                              );

                                          _messageController.text = uploadedUrl;
                                          _sendMessage();

                                          await Future.delayed(
                                            Duration(milliseconds: 100),
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        }
                                      },
                                      child: Text(
                                        'Send',
                                        style: GoogleFonts.cabin(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                  contentPadding: EdgeInsets.all(10),

                                  content: SizedBox(
                                    width: 100,
                                    height: resultList.length < 2 ? 132 : 270,
                                    child: GridView.count(
                                      crossAxisCount:
                                          resultList.length < 2
                                              ? resultList.length
                                              : 2,
                                      mainAxisSpacing: 5,
                                      crossAxisSpacing: 5,
                                      children: List.generate(
                                        resultList.length,
                                        (index) {
                                          File asset = resultList[index];
                                          if (asset.path.endsWith('.mp4')) {
                                            return Container(
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: VideoWidget(file: asset),
                                            );
                                          } else {
                                            return Container(
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: SizedBox(
                                                  width: 3,
                                                  height: 3,
                                                  child: Image.file(asset),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                          );
                        }
                      }
                    } catch (e) {
                      logger.e(e);
                    }
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.file_copy_rounded, color: Colors.grey[600]),
                      SizedBox(width: 10),
                      Text(
                        'file',
                        style: GoogleFonts.cabin(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
              ];
            },
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
