import 'package:driver_app/back/tools/image_picker.dart';
import 'package:driver_app/back/upload_files/personal_data/upload_photos_save.dart';
import 'package:driver_app/db/user_data/store_role.dart';
import 'package:driver_app/front/displayed_items/intermediate_page_for_forms.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalDataForm extends ConsumerStatefulWidget {
  const PersonalDataForm({super.key});

  @override
  ConsumerState<PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends ConsumerState<PersonalDataForm> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  dynamic personalPhoto;
  List<XFile> driverLicensePhoto = <XFile>[];
  List<XFile> iDPhoto = <XFile>[];
  String error = "No Error Detected";

  Future<void> _saveTempPersonalPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    if (personalPhoto != null) {
      await prefs.setString('personalPhotoPath', personalPhoto.path);
    }
    await prefs.setStringList(
      'driverLicensePhotoPaths',
      driverLicensePhoto.map((x) => x.path).toList(),
    );
    await prefs.setStringList(
      'idPhotoPaths',
      iDPhoto.map((x) => x.path).toList(),
    );
  }

  Future<void> _loadTempPersonalPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final personalPhotoPath = prefs.getString('personalPhotoPath');
    if (personalPhotoPath != null) {
      personalPhoto = XFile(personalPhotoPath);
    }

    final driverPaths = prefs.getStringList('driverLicensePhotoPaths') ?? [];
    final idPaths = prefs.getStringList('idPhotoPaths') ?? [];

    driverLicensePhoto = driverPaths.map((path) => XFile(path)).toList();
    iDPhoto = idPaths.map((path) => XFile(path)).toList();
    setState(() {});
  }

  Future<void> _clearTempPersonalPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('personalPhotoPath');
    await prefs.remove('driverLicensePhotoPaths');
    await prefs.remove('idPhotoPaths');
  }

  bool _allFilledOut(String role) {
    if (personalPhoto != null &&
        driverLicensePhoto.isNotEmpty &&
        iDPhoto.isNotEmpty &&
        role != 'Guide') {
      return true;
    } else if (personalPhoto != null &&
        driverLicensePhoto.isNotEmpty &&
        iDPhoto.isNotEmpty &&
        role == 'Guide') {
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
    _loadTempPersonalPhotos();
  }

  Future<void> _submitForm() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await uploadPhotosAndSaveData(
        userId: userId,
        personalPhoto: personalPhoto,
        driverLicensePhotos: driverLicensePhoto,
        idPhotos: iDPhoto,
        context: context,
      );
      await _clearTempPersonalPhotos();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final roleDetails = ref.watch(roleProvider);
    final role = roleDetails?['Role'];
    String numOfPages = role == 'Guide' ? '1/3' : '1/4';

    if (role == null) {
      return Center(child: CircularProgressIndicator());
    }

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
            '$numOfPages Your Key Details to Get Started',
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
                  '$numOfPages Your Key Details to Get Started',
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
                  'We\'re almost there! Share a few important details to complete your profile and set the stage for an exciting partnership ahead.',
                ),
                SizedBox(height: height * 0.015),
                Row(
                  children: [
                    Text('Please Upload Your Photo'),
                    Spacer(),
                    IconButton(
                      onPressed: () async {
                        final selected =
                            await ImagePickerHelper.selectSinglePhoto(
                              context: context,
                            );
                        if (selected == null) return;
                        setState(() => personalPhoto = selected);
                        await _saveTempPersonalPhotos();
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
                      child: ImageGrid(images: [personalPhoto]),
                    ),
                SizedBox(height: height * 0.015),
                Row(
                  children: [
                    Text('Please Upload Your ID Photo (Front and Back)'),
                    Spacer(),
                    IconButton(
                      onPressed: () async {
                        final images =
                            await ImagePickerHelper.selectMultiplePhotos(
                              context: context,
                            );
                        if (images != null) {
                          setState(() => iDPhoto.addAll(images));
                          await _saveTempPersonalPhotos();
                        }
                      },
                      icon: Icon(Icons.add),
                    ),
                  ],
                ),
                iDPhoto.isEmpty
                    ? SizedBox.shrink()
                    : Container(
                      width: width,
                      height: height / 5,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(113, 80, 79, 79),
                        borderRadius: BorderRadius.circular(width * 0.019),
                      ),
                      padding: EdgeInsets.all(width * 0.02),
                      child: ImageGrid(images: iDPhoto),
                    ),
                SizedBox(height: height * 0.025),
                role == 'Guide'
                    ? SizedBox.shrink()
                    : Row(
                      children: [
                        Text('Please Upload Your Driver License Photo'),
                        Spacer(),
                        IconButton(
                          onPressed: () async {
                            final images =
                                await ImagePickerHelper.selectMultiplePhotos(
                                  context: context,
                                );
                            if (images != null) {
                              setState(() => driverLicensePhoto.addAll(images));
                              await _saveTempPersonalPhotos();
                            }
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
                      child: ImageGrid(images: driverLicensePhoto),
                    ),
                SizedBox(height: height * 0.025),
                GestureDetector(
                  onTap: () {
                    if (_allFilledOut(role)) {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          child: IntermediateFormPage(
                            isFromPersonalDataForm: true,
                            isFromBankDetailsForm: false,
                            isFromCarDetailsForm: false,
                            isFromCertificateDetailsForm: false,
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
                          _allFilledOut(role)
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
                              _allFilledOut(role)
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
                SizedBox(height: height * 0.025),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
