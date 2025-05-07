import 'dart:io';

import 'package:driver_app/back/upload_files/certificates/upload_certificate_save.dart';
import 'package:driver_app/front/auth/forms/application_forms/bank_details_form.dart';
import 'package:driver_app/front/displayed_items/intermediate_page_for_forms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CertificatesDetails extends ConsumerStatefulWidget {
  final String role;
  const CertificatesDetails({super.key, required this.role});

  @override
  ConsumerState<CertificatesDetails> createState() =>
      _CertificatesDetailsState();
}

class _CertificatesDetailsState extends ConsumerState<CertificatesDetails> {
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
    _saveTempCertificates();
  }

  Future<void> pickFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result != null) {
      PlatformFile doc = result.files.first;
      final file = File(doc.path!);
      updateCertificate(index, 'file', file);
      updateCertificate(index, 'file name', doc.name);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File uploaded: ${doc.name}')));
      }
    } else if (certificates[index]['file'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No file selected')));
      }
    }
  }

  Future<void> _submitForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    await uploadCertificateAndSave(
      userId: userId,
      certificates: certificates,
      context: context,
    );
    await _clearTempCertificates();
  }

  Widget buildCertificateField({
    required int index,
    required double width,
    required double height,
    required bool darkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: width,
          height: height * 0.065,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  _certificateNameFocusNode.hasFocus
                      ? Colors.blue
                      : const Color.fromARGB(255, 189, 189, 189),
            ),
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
            onEditingComplete: () {
              _certificateNameFocusNode.unfocus();
              FocusScope.of(context).requestFocus(_certificateTypeFocusNode);
            },
            decoration: InputDecoration(
              errorBorder: InputBorder.none,
              contentPadding: EdgeInsets.only(top: width * 0.05),
              isDense: true,
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              labelText: 'Certificate Name',
              hintText: 'Please enter Certificate Name',
              hintStyle: TextStyle(
                fontSize: width * 0.038,
                color: Colors.grey.shade500.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
              labelStyle: TextStyle(
                fontSize: width * 0.038,
                color:
                    _certificateNameFocusNode.hasFocus
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
        SizedBox(height: 10),
        Container(
          width: width,
          height: height * 0.065,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  _certificateTypeFocusNode.hasFocus
                      ? Colors.blue
                      : Colors.grey.shade400,
            ),
            borderRadius: BorderRadius.circular(width * 0.019),
          ),
          padding: EdgeInsets.only(
            bottom: 0,
            left: width * 0.025,
            top: width * 0.025,
            right: width * 0.025,
          ),
          child: DropdownButtonFormField<String>(
            items:
                ['Driver', 'Language', 'Guide']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        alignment: Alignment.centerLeft,
                        child: Text(type),
                      ),
                    )
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
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              labelText: 'Certificate Type',
              hintStyle: TextStyle(
                fontSize: width * 0.038,
                color: Colors.grey.shade500.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
              labelStyle: TextStyle(
                fontSize: width * 0.038,
                color:
                    _certificateTypeFocusNode.hasFocus
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
                color:
                    certificates[index]['fileUrl'] != null
                        ? Colors.green
                        : Colors.grey,
                size: width * 0.101,
              ),
              SizedBox(width: width * 0.025),
              Text(
                certificates[index]['file name'] ?? 'Upload Certificate',
                style: TextStyle(
                  color:
                      certificates[index]['file'] != null
                          ? Theme.of(context).textTheme.bodyMedium?.color!
                          : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: height * 0.023),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 5 && !_showTitle) {
        setState(() {
          _showTitle = true;
        });
      } else if (_scrollController.offset <= 5 && _showTitle) {
        setState(() {
          _showTitle = false;
        });
      }
    });
    _certificateNameFocusNode = FocusNode();
    _certificateTypeFocusNode = FocusNode();
    certificates.add({
      'name': '',
      'type': null,
      'file': null,
      'file name': null,
    });

    _loadTempCertificates();
  }

  Future<void> _saveTempCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final certList =
        certificates.map((cert) {
          return {'name': cert['name'], 'type': cert['type']};
        }).toList();

    await prefs.setString('certificates', certList.toString());
  }

  Future<void> _loadTempCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('certificates');
    if (raw != null) {
      final matches = RegExp(r'\{.*?\}').allMatches(raw);
      final restored =
          matches.map((m) {
            final item = m.group(0)!;
            final name =
                RegExp(r'name: (.*?),').firstMatch(item)?.group(1)?.trim() ??
                '';
            final type =
                RegExp(r'type: (.*?)\}').firstMatch(item)?.group(1)?.trim();
            return {
              'name': name,
              'type': type == 'null' ? null : type,
              'file': null,
              'file name': null,
            };
          }).toList();

      setState(() {
        certificates = restored;
      });
    }
  }

  Future<void> _clearTempCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('certificates');
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
    String numOfPages = role == 'Guide' ? '2/3' : '2/4';

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
            size: width * 0.1,
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
              fontSize: width * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numOfPages Showcase Your Expertise',
                  style: GoogleFonts.daysOne(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.066,
                      color: darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.025),
                Text(
                  'Have certifications that highlight your skills or qualifications? Add them here to build trust and credibility as our partner.',
                ),
                SizedBox(height: height * 0.015),
                ...certificates.asMap().entries.map((entry) {
                  int index = entry.key;
                  return buildCertificateField(
                    index: index,
                    width: width,
                    height: height,
                    darkMode: darkMode,
                  );
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
                SizedBox(height: height * 0.023),
                GestureDetector(
                  onTap: () async {
                    if (_allFilledOut()) {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          child: IntermediateFormPage(
                            isFromPersonalDataForm: false,
                            isFromCarDetailsForm: false,
                            isFromBankDetailsForm: false,
                            isFromCertificateDetailsForm: true,
                            isFromCarDetailsSwitcher: false,
                            isFromProfilePage: false,
                            backgroundProcess: _submitForm,
                          ),
                        ),
                      );
                    }
                  },

                  child: Container(
                    width: width,
                    height: height * 0.058,
                    decoration: BoxDecoration(
                      color:
                          _allFilledOut()
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
                        'Next',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: width * 0.04,
                          color:
                              _allFilledOut()
                                  ? (darkMode
                                      ? const Color.fromARGB(255, 0, 0, 0)
                                      : const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ))
                                  : (darkMode
                                      ? const Color.fromARGB(132, 0, 0, 0)
                                      : const Color.fromARGB(
                                        187,
                                        255,
                                        255,
                                        255,
                                      )),
                        ),
                      ),
                    ),
                  ),
                ),

                Center(
                  child: TextButton(
                    onPressed: () async {
                      await _clearTempCertificates();
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BankDetailsForm(),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Skip this step',
                      style: GoogleFonts.robotoCondensed(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.w500,
                        color: darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
