import 'package:driver_app/db/user_data/store_role.dart';
import 'package:driver_app/front/auth/certificates_details.dart';
import 'package:driver_app/front/auth/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';

class PersonalDataForm extends ConsumerStatefulWidget {
  const PersonalDataForm({super.key});

  @override
  ConsumerState<PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends ConsumerState<PersonalDataForm> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  final _vATnumberController = TextEditingController();
  dynamic personalPhoto;
  List<Asset> driverLicensePhoto = <Asset>[];
  String error = "No Error Detected";

  late FocusNode _vATnumberFocusNode;

  bool isVATnumberEmpty = false;

  bool _allFilledOut() {
    if (_vATnumberController.text.isNotEmpty &&
        personalPhoto != null &&
        driverLicensePhoto.isNotEmpty) {
      return true;
    }
    return false;
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

    _vATnumberFocusNode = FocusNode();

    _vATnumberFocusNode.addListener(() {
      if (!_vATnumberFocusNode.hasFocus) {
        _isEmpty(_vATnumberController, 'VAT Number');
      }
    });

    _vATnumberController.addListener(() {
      setState(() {});
    });
  }

  void _isEmpty(TextEditingController controller, String fieldName) {
    setState(() {
      if (controller.text.isEmpty) {
        if (fieldName == 'VAT Number') {
          isVATnumberEmpty = true;
        }
      } else {
        if (fieldName == 'VAT Number') {
          isVATnumberEmpty = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _vATnumberController.dispose();
    _vATnumberFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final role = ref.watch(roleProvider);
    String numOfPages = role == 'Guide' ? '1/2' : '1/3';

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
            '$numOfPages Your Key Details to Get Started',
            overflow: TextOverflow.visible,
            softWrap: true,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                  '$numOfPages Your Key Details to Get Started',
                  style: GoogleFonts.daysOne(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      color: darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.025),
                Text(
                  'We\'re almost there! Share a few important details to complete your profile and set the stage for an exciting partnership ahead.',
                ),
                SizedBox(height: height * 0.015),
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isVATnumberEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _vATnumberFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: _vATnumberFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          _vATnumberFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_vATnumberController, 'VAT Number');
                        setState(() {
                          _vATnumberFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _vATnumberFocusNode,
                      textInputAction: TextInputAction.next,
                      controller: _vATnumberController,
                      decoration: InputDecoration(
                        suffixIcon:
                            _vATnumberFocusNode.hasFocus
                                ? _vATnumberController.text.isEmpty
                                    ? Icon(
                                      Icons.cancel_outlined,
                                      size: width * 0.076,
                                      color: const Color.fromARGB(
                                        255,
                                        158,
                                        158,
                                        158,
                                      ),
                                    )
                                    : IconButton(
                                      onPressed: () {
                                        _vATnumberController.clear();
                                      },
                                      icon: Icon(Icons.cancel),
                                      padding: EdgeInsets.zero,
                                      iconSize: width * 0.076,
                                    )
                                : null,
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
                        labelText: 'VAT Number',
                        hintText: 'Bank Details',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 15,
                          color:
                              isVATnumberEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _vATnumberFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isVATnumberEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.025),
                Text(
                  'Attachments',
                  style: GoogleFonts.daysOne(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.005),
                Row(
                  children: [
                    Text('Please Upload Your Photo'),
                    Spacer(),
                    IconButton(
                      onPressed: () async {
                        var resultList = await loadAssets(
                          error: error,
                          maxNumOfPhotos: 1,
                          minNumOfPhotos: 1,
                        );
                        setState(() {
                          personalPhoto = resultList.first;
                        });
                      },
                      icon: Icon(Icons.add),
                    ),
                  ],
                ),
                personalPhoto == null
                    ? SizedBox.shrink()
                    : Container(
                      width: width,
                      height: height / 5,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(113, 80, 79, 79),
                        borderRadius: BorderRadius.circular(width * 0.019),
                      ),
                      padding: EdgeInsets.all(width * 0.02),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: AssetThumb(
                          asset: personalPhoto,
                          width: (width * 0.254).toInt(),
                          height: (height * 0.117).toInt(),
                        ),
                      ),
                    ),
                SizedBox(height: height * 0.015),
                role == 'Guide'
                    ? SizedBox.shrink()
                    : Row(
                      children: [
                        Text('Please Upload Your Driver License Photo'),
                        Spacer(),
                        IconButton(
                          onPressed: () async {
                            var resultList = await loadAssets(
                              error: error,
                              maxNumOfPhotos: 2,
                              minNumOfPhotos: 2,
                            );
                            setState(() {
                              driverLicensePhoto = resultList;
                            });
                          },
                          icon: Icon(Icons.add),
                        ),
                      ],
                    ),
                driverLicensePhoto.isEmpty
                    ? SizedBox.shrink()
                    : Container(
                      width: width,
                      height: height / 5,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(113, 80, 79, 79),
                        borderRadius: BorderRadius.circular(width * 0.019),
                      ),
                      padding: EdgeInsets.all(width * 0.02),
                      child: buildGridView(
                        images: driverLicensePhoto,
                        height: height,
                        width: width,
                      ),
                    ),
                SizedBox(height: height * 0.025),
                GestureDetector(
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CertificatesDetails(role: role!),
                      ),
                    );
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
                          fontSize: 16,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
