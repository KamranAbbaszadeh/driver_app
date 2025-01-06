import 'dart:convert';
import 'dart:typed_data';

import 'package:driver_app/front/auth/car_details_form.dart';
import 'package:driver_app/front/auth/waiting_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CertificatesDetails extends StatefulWidget {
  final String role;
  const CertificatesDetails({
    super.key,
    required this.role,
  });

  @override
  State<CertificatesDetails> createState() => _CertificatesDetailsState();
}

class _CertificatesDetailsState extends State<CertificatesDetails> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  List<Map<String, dynamic>> certificates = [];
  bool _allFilledOut() {
    if (certificates.isEmpty) {
      return false;
    }

    for (Map<String, dynamic> certificate in certificates) {
      if (certificate.values.any((value) => value == null)) {
        return false;
      }
    }

    return true;
  }

  late FocusNode _certificateNameFocusNode;
  late FocusNode _certificateTypeFocusNode;

  void addCertificate() {
    setState(() {
      certificates.add({'name': '', 'type': null, 'file': null});
    });
  }

  void updateCertificate(int index, String key, dynamic value) {
    setState(() {
      certificates[index][key] = value;
    });
  }

  String? convertToBase64(Uint8List? data) {
    if (data == null) {
      return null;
    }
    print(base64Encode(data));
    return base64Encode(data);
  }

  Future<void> pickFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      var fileUrl = convertToBase64(file.bytes);
      updateCertificate(index, 'fileUrl', fileUrl);
      updateCertificate(index, 'file name', file.name);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fine uploaded: ${file.name}'),
        ),
      );
    } else if (certificates[index]['file'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No file selected'),
        ),
      );
    }
  }

  Widget buildCertificateField({
    required int index,
    required double width,
    required double height,
    required bool darkMode,
  }) {
    return Padding(
      padding: EdgeInsets.all(width * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width,
            height: height * 0.065,
            decoration: BoxDecoration(
              border: Border.all(
                  color: _certificateNameFocusNode.hasFocus
                      ? Colors.blue
                      : const Color.fromARGB(255, 189, 189, 189)),
              borderRadius: BorderRadius.circular(width * 0.019),
            ),
            padding: EdgeInsets.only(
              bottom: _certificateNameFocusNode.hasFocus ? 0 : width * 0.025,
              left: width * 0.025,
              top: width * 0.025,
              right: width * 0.025,
            ),
            child: TextFormField(
              showCursor: false,
              focusNode: _certificateNameFocusNode,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                errorBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(top: width * 0.05),
                isDense: true,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                labelText: 'Certificate Name',
                hintText: 'Please enter Certificate Name',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
                labelStyle: TextStyle(
                  fontSize: 15,
                  color: _certificateNameFocusNode.hasFocus
                      ? Colors.blue
                      : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onChanged: (value) => updateCertificate(index, 'name', value),
              onTap: () {
                setState(() {
                  _certificateNameFocusNode.requestFocus();
                });
              },
              onTapOutside: (event) {
                setState(() {
                  _certificateNameFocusNode.unfocus();
                });
              },
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            width: width,
            height: height * 0.065,
            decoration: BoxDecoration(
              border: Border.all(
                  color: _certificateTypeFocusNode.hasFocus
                      ? Colors.blue
                      : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(width * 0.019),
            ),
            padding: EdgeInsets.only(
              bottom: 0,
              left: width * 0.025,
              top: width * 0.025,
              right: width * 0.025,
            ),
            child: DropdownButtonFormField<String>(
              items: ['Driver', 'Language', 'Guide']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        alignment: Alignment.centerLeft,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                updateCertificate(index, 'type', value);
                setState(() {
                  _certificateTypeFocusNode.unfocus();
                });
              },
              onTap: () {
                setState(() {
                  _certificateTypeFocusNode.requestFocus();
                });
              },
              focusNode: _certificateTypeFocusNode,
              dropdownColor: darkMode ? Colors.black : Colors.white,
              decoration: InputDecoration(
                errorBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(top: width * 0.05),
                isDense: true,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                labelText: 'Certificate Type',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
                labelStyle: TextStyle(
                  fontSize: 15,
                  color: _certificateTypeFocusNode.hasFocus
                      ? Colors.blue
                      : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () => pickFile(index),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: certificates[index]['fileUrl'] != null
                      ? Colors.green
                      : Colors.grey,
                  size: 40,
                ),
                SizedBox(width: 10),
                Text(
                  certificates[index]['file name'] ?? 'Upload Certificate',
                  style: TextStyle(
                    color: certificates[index]['file'] != null
                        ? Theme.of(context).textTheme.bodyMedium?.color!
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () {
        if (_scrollController.offset > 5 && !_showTitle) {
          setState(() {
            _showTitle = true;
          });
        } else if (_scrollController.offset <= 5 && _showTitle) {
          setState(() {
            _showTitle = false;
          });
        }
      },
    );
    _certificateNameFocusNode = FocusNode();
    _certificateTypeFocusNode = FocusNode();
    certificates
        .add({'name': '', 'type': null, 'file': null, 'file name': null});
  }

  @override
  void dispose() {
    _certificateNameFocusNode.dispose();
    _certificateTypeFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final role = widget.role;
    String numOfPages = role == 'Guide' ? '2/2' : '2/3';

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        surfaceTintColor: darkMode ? Colors.black : Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          hoverColor: Colors.transparent,
          icon: Icon(
            Icons.arrow_circle_left_rounded,
            size: width * 0.127,
            color: Colors.grey.shade400,
          ),
        ),
        toolbarHeight: height * 0.1,
        title: AnimatedOpacity(
          opacity: _showTitle ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
          child: Text(
            '$numOfPages Showcase Your Expertise',
            overflow: TextOverflow.visible,
            softWrap: true,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numOfPages Showcase Your Expertise',
                  style: GoogleFonts.daysOne(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      color: darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                SizedBox(
                  height: height * 0.025,
                ),
                Text(
                  'Have certifications that highlight your skills or qualifications? Add them here to build trust and credibility as our partner.',
                ),
                SizedBox(
                  height: height * 0.015,
                ),
                ...certificates.asMap().entries.map((entry) {
                  int index = entry.key;
                  return buildCertificateField(
                      index: index,
                      width: width,
                      height: height,
                      darkMode: darkMode);
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: addCertificate,
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          darkMode
                              ? Color.fromARGB(255, 1, 105, 170)
                              : Color.fromARGB(255, 0, 134, 179),
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          darkMode
                              ? const Color.fromARGB(255, 0, 0, 0)
                              : const Color.fromARGB(255, 255, 255, 255),
                        ),
                        shape: WidgetStatePropertyAll(
                          ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      child: Text('Add Another Certificate'),
                    ),
                    Spacer(),
                    certificates.length > 1
                        ? ElevatedButton(
                            onPressed: () {
                              setState(() {
                                certificates.removeLast();
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                darkMode
                                    ? Color.fromARGB(255, 1, 105, 170)
                                    : Color.fromARGB(255, 0, 134, 179),
                              ),
                              foregroundColor: WidgetStatePropertyAll(
                                darkMode
                                    ? const Color.fromARGB(255, 0, 0, 0)
                                    : const Color.fromARGB(255, 255, 255, 255),
                              ),
                              shape: WidgetStatePropertyAll(
                                ContinuousRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            child: Text('Delete'),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            role == 'Guide' ? WaitingPage() : CarDetailsForm(),
                      ),
                    );
                  },
                  child: Container(
                    width: width,
                    height: height * 0.058,
                    decoration: BoxDecoration(
                      color: _allFilledOut()
                          ? (darkMode
                              ? Color.fromARGB(255, 1, 105, 170)
                              : Color.fromARGB(255, 0, 134, 179))
                          : (darkMode
                              ? Color.fromARGB(128, 52, 168, 235)
                              : Color.fromARGB(177, 0, 134, 179)),
                      borderRadius: BorderRadius.circular(7.5),
                    ),
                    child: Center(
                      child: Text(
                        role == 'Guide' ? 'Submit' : 'Next',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _allFilledOut()
                              ? (darkMode
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : const Color.fromARGB(255, 255, 255, 255))
                              : (darkMode
                                  ? const Color.fromARGB(132, 0, 0, 0)
                                  : const Color.fromARGB(187, 255, 255, 255)),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
