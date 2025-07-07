// Certificate details form page for uploading professional credentials.
// Allows users to add up to 3 certificates with name, type, and file upload.
import 'dart:io';

import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/upload_files/certificates/upload_certificate_save.dart';
import 'package:onemoretour/front/auth/forms/application_forms/bank_details_form.dart';
import 'package:onemoretour/front/displayed_items/intermediate_page_for_forms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool validateCertificateName(String value) {
  return RegExp(r"^[A-Za-z0-9\s\-,.]{2,100}$").hasMatch(value);
}

/// A form screen for entering and uploading professional certificates.
/// Supports adding, editing, and removing certificates with validations and temporary saving.
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
  List<bool> isCertificateNameEmpty = [];
  /// Validates that all certificate fields are properly filled for submission.
  bool _allFilledOut() {
    if (certificates.isEmpty) return false;

    for (var cert in certificates) {
      if (cert['name'] == null ||
          !validateCertificateName(cert['name'].toString().trim())) {
        return false;
      }
      if (cert['type'] == null) {
        return false;
      }
      if (cert['file'] == null && cert['fileUrl'] == null) {
        return false;
      }
    }

    return true;
  }

  List<FocusNode> certificateNameFocusNodes = [];
  List<FocusNode> certificateTypeFocusNodes = [];

  /// Adds a new empty certificate form, limited to a maximum of 3.
  void addCertificate() {
    if (certificates.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 3 certificates.')),
      );
      return;
    }

    setState(() {
      certificates.add({'name': '', 'type': null, 'file': null});
      certificateNameFocusNodes.add(FocusNode());
      certificateTypeFocusNodes.add(FocusNode());
      isCertificateNameEmpty.add(false);
      certificateNameFocusNodes.last.addListener(() {
        setState(() {
          if (!certificateNameFocusNodes.last.hasFocus) {
            final name = certificates.last['name']?.toString() ?? '';
            isCertificateNameEmpty[isCertificateNameEmpty.length - 1] =
                name.isEmpty ? true : !validateCertificateName(name);
          }
        });
      });
    });
  }

  /// Deletes the file from Firebase Storage (if uploaded) and clears local file info.
  Future<void> deleteFile(int index) async {
    if (certificates[index]['fileUrl'] != null) {
      try {
        final oldRef = FirebaseStorage.instance.refFromURL(
          certificates[index]['fileUrl'],
        );
        await oldRef.delete();
      } catch (e) {
        logger.e('Failed to delete file from Storage: $e');
      }
    }
    setState(() {
      certificates[index]['file'] = null;
      certificates[index]['file name'] = null;
      certificates[index]['fileUrl'] = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File removed')));
    }
  }

  /// Updates a specific certificate's data in state and triggers save.
  void updateCertificate(int index, String key, dynamic value) {
    setState(() {
      certificates[index][key] = value;
    });
    logger.d(
      "Certificate with index: $index is updated. Result: ${certificates[index]}",
    );
    _saveTempCertificates();
  }

  /// Updates a specific certificate's data in state and triggers save.
  void updateCertificateFile({
    required int index,
    required String fileName,
    required dynamic file,
  }) {
    try {
      setState(() {
        certificates[index]['file name'] = fileName;
        certificates[index]['file'] = file.path;
      });
    } on Exception catch (e) {
      logger.e(e);
    }
    logger.d(
      "Certificate with index: $index is updated. Result: ${certificates[index]}",
    );
    try {
      _saveTempCertificates();
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  /// Opens a file picker and updates selected certificate with uploaded file.
  /// Enforces a 5MB file size limit and valid extensions.
  Future<void> pickFile(int index) async {
    if (certificates[index]['fileUrl'] != null) {
      try {
        final oldRef = FirebaseStorage.instance.refFromURL(
          certificates[index]['fileUrl'],
        );
        await oldRef.delete();
      } catch (_) {}
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
      ],
      withData: true,
    );

    if (result != null) {
      PlatformFile doc = result.files.first;
      final maxSizeInBytes = 5 * 1024 * 1024;
      if (doc.size > maxSizeInBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File too large. Max allowed size is 5MB.')),
          );
        }
        return;
      }
      final file = File(doc.path!);
      updateCertificateFile(index: index, fileName: doc.name, file: file);
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

  /// Uploads certificates and clears temporary storage upon form submission.
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

  /// Builds UI for a single certificate entry with name input, dropdown, and file picker.
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
                  certificateNameFocusNodes[index].hasFocus
                      ? Colors.blue
                      : const Color.fromARGB(255, 189, 189, 189),
            ),
            borderRadius: BorderRadius.circular(width * 0.019),
          ),
          padding: EdgeInsets.only(
            bottom:
                certificateNameFocusNodes[index].hasFocus ? 0 : width * 0.025,
            left: width * 0.025,
            top: width * 0.025,
            right: width * 0.025,
          ),
          child: TextFormField(
            showCursor: true,
            cursorColor:
                darkMode
                    ? Color.fromARGB(255, 1, 105, 170)
                    : Color.fromARGB(255, 0, 134, 179),
            cursorHeight: height * 0.02,
            focusNode: certificateNameFocusNodes[index],
            onEditingComplete: () {
              certificateNameFocusNodes[index].unfocus();
              FocusScope.of(
                context,
              ).requestFocus(certificateTypeFocusNodes[index]);
            },
            initialValue:
                certificates.isNotEmpty ? certificates[index]['name'] : null,
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
                    certificateNameFocusNodes[index].hasFocus
                        ? Colors.blue
                        : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: (value) {
              updateCertificate(index, 'name', value);
              setState(() {
                isCertificateNameEmpty[index] =
                    value.trim().isEmpty
                        ? true
                        : !validateCertificateName(value.trim());
              });
            },
            onTap: () {
              setState(() {
                certificateNameFocusNodes[index].requestFocus();
              });
            },
            onTapOutside: (event) {
              setState(() {
                certificateNameFocusNodes[index].unfocus();
              });
            },
          ),
        ),
        if (isCertificateNameEmpty.length > index &&
            isCertificateNameEmpty[index])
          Padding(
            padding: EdgeInsets.only(left: width * 0.027, top: width * 0.007),
            child: Text(
              certificates[index]['name'].toString().isEmpty
                  ? "Required"
                  : "Invalid format",
              style: TextStyle(
                fontSize: width * 0.03,
                color: Color.fromARGB(255, 244, 92, 54),
              ),
            ),
          ),
        SizedBox(height: height * 0.011),
        Container(
          width: width,
          height: height * 0.065,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  certificateTypeFocusNodes[index].hasFocus
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
            value: certificates.isNotEmpty ? certificates[index]['type'] : null,
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
                certificateTypeFocusNodes[index].unfocus();
              });
            },
            onTap: () {
              setState(() {
                certificateTypeFocusNodes[index].requestFocus();
              });
            },
            focusNode: certificateTypeFocusNodes[index],

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
                    certificateTypeFocusNodes[index].hasFocus
                        ? Colors.blue
                        : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: height * 0.011),
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
              Expanded(
                child: Text(
                  certificates[index]['fileUrl'] != null
                      ? ''
                      : certificates[index]['file name'] ??
                          'Upload Certificate',
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        certificates[index]['file'] != null
                            ? Theme.of(context).textTheme.bodyMedium?.color!
                            : Colors.grey,
                  ),
                ),
              ),
              Spacer(),
              certificates[index]['file name'] == null
                  ? SizedBox.shrink()
                  : IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () => deleteFile(index),
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

    _loadTempCertificates().then((_) {
      if (certificates.isEmpty) {
        setState(() {
          certificates.add({
            'name': '',
            'type': null,
            'file': null,
            'file name': null,
          });
          certificateNameFocusNodes.add(FocusNode());
          certificateTypeFocusNodes.add(FocusNode());
          isCertificateNameEmpty.add(false);
        });
      }
    });
  }

  /// Stores and retrieves temporary certificate form data using SharedPreferences.
  Future<void> _saveTempCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final certList =
        certificates.map((cert) {
          return {'name': cert['name'], 'type': cert['type']};
        }).toList();

    await prefs.setString('certificates', certList.toString());
  }

  /// Stores and retrieves temporary certificate form data using SharedPreferences.
  Future<void> _loadTempCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .get();

        final certData = doc.data()?['certificates'];
        List<Map<String, dynamic>> certs = [];

        if (certData is List) {
          certs =
              certData
                  .map<Map<String, dynamic>>(
                    (cert) => {
                      'name': cert['name'],
                      'type': cert['type'],
                      'fileUrl': cert['doc'],
                      'file name': cert['fileName'],
                    },
                  )
                  .toList();
        } else if (certData is Map) {
          certs =
              certData.values
                  .map<Map<String, dynamic>>(
                    (e) => {
                      'name': e['name'],
                      'type': e['type'],
                      'fileUrl': e['doc'],
                      'file name': e['fileName'],
                    },
                  )
                  .toList();
        }

        if (certs.isNotEmpty) {
          setState(() {
            certificates = certs;

            certificateNameFocusNodes = List.generate(
              certificates.length,
              (_) => FocusNode(),
            );
            certificateTypeFocusNodes = List.generate(
              certificates.length,
              (_) => FocusNode(),
            );
            isCertificateNameEmpty = List.generate(
              certificates.length,
              (_) => false,
            );
          });
          return;
        }
      }
    } on Exception catch (e) {
      logger.e("error in load data from firebase: $e");
    }

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

        certificateNameFocusNodes = List.generate(
          certificates.length,
          (_) => FocusNode(),
        );
        certificateTypeFocusNodes = List.generate(
          certificates.length,
          (_) => FocusNode(),
        );
        isCertificateNameEmpty = List.generate(
          certificates.length,
          (_) => false,
        );
      });
    }
  }

  Future<void> _clearTempCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('certificates');
  }

  @override
  void dispose() {
    for (var node in certificateNameFocusNodes) {
      node.dispose();
    }
    for (var node in certificateTypeFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (int i = 0; i < certificates.length; i++) {
      if (certificateNameFocusNodes.length > i) {
        certificateNameFocusNodes[i].addListener(() {
          setState(() {
            if (!certificateNameFocusNodes[i].hasFocus) {
              final name = certificates[i]['name']?.toString() ?? '';
              isCertificateNameEmpty[i] =
                  name.isEmpty ? true : !validateCertificateName(name);
            }
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final role = widget.role;
    String numOfPages = role == 'Guide' ? '2/3' : '2/4';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: darkMode ? Colors.black : Colors.white,
          surfaceTintColor: darkMode ? Colors.black : Colors.white,
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
                      _allFilledOut() && certificates.length < 3
                          ? ElevatedButton(
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
                          )
                          : SizedBox.shrink(),
                      Spacer(),
                      certificates.length > 1
                          ? ElevatedButton(
                            onPressed: () {
                              setState(() {
                                certificates.removeLast();
                                certificateNameFocusNodes
                                    .removeLast()
                                    .dispose();
                                certificateTypeFocusNodes
                                    .removeLast()
                                    .dispose();
                                isCertificateNameEmpty.removeLast();
                                for (
                                  int i = 0;
                                  i < certificateNameFocusNodes.length;
                                  i++
                                ) {
                                  certificateNameFocusNodes[i].removeListener(
                                    () {},
                                  );
                                  certificateNameFocusNodes[i].addListener(() {
                                    setState(() {
                                      if (!certificateNameFocusNodes[i]
                                          .hasFocus) {
                                        final name =
                                            certificates[i]['name']
                                                ?.toString() ??
                                            '';
                                        isCertificateNameEmpty[i] =
                                            name.isEmpty
                                                ? true
                                                : !validateCertificateName(
                                                  name,
                                                );
                                      }
                                    });
                                  });
                                }
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
                  // Navigate to next form step if all certificates are filled.
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
                                    ? Color.fromARGB(40, 52, 168, 235)
                                    : Color.fromARGB(40, 0, 134, 179)),
                        borderRadius: BorderRadius.circular(width * 0.019),
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

                  // Skip certificate entry and go to the bank details form.
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
      ),
    );
  }
}
