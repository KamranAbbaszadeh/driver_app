import 'package:driver_app/back/tools/image_picker.dart';
import 'package:driver_app/back/tools/loading_notifier.dart';
import 'package:driver_app/back/upload_files/personal_data/upload_photos_save.dart';
import 'package:driver_app/db/user_data/store_role.dart';
import 'package:driver_app/front/auth/forms/application_forms/certificates_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PersonalDataForm extends ConsumerStatefulWidget {
  const PersonalDataForm({super.key});

  @override
  ConsumerState<PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends ConsumerState<PersonalDataForm> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  dynamic personalPhoto;
  List<Asset> driverLicensePhoto = <Asset>[];
  List<Asset> iDPhoto = <Asset>[];
  String error = "No Error Detected";

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
    final role = ref.watch(roleProvider);
    final isLoading = ref.watch(loadingProvider);
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
                        if (await Permission.photos.request().isGranted) {
                          var resultList = await loadAssets(
                            error: error,
                            maxNumOfPhotos: 1,
                            minNumOfPhotos: 1,
                          );
                          setState(() {
                            personalPhoto = resultList.first;
                          });
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Permission to access photos is required.',
                                ),
                              ),
                            );
                          }
                        }
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
                Row(
                  children: [
                    Text('Please Upload Your ID Photo (Front and Back)'),
                    Spacer(),
                    IconButton(
                      onPressed: () async {
                        var resultList = await loadAssets(
                          error: error,
                          maxNumOfPhotos: 2,
                          minNumOfPhotos: 2,
                        );
                        setState(() {
                          iDPhoto = resultList;
                        });
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
                      child: buildGridView(
                        images: iDPhoto,
                        height: height,
                        width: width,
                      ),
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
                    if (_allFilledOut(role)) {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        ref.read(loadingProvider.notifier).startLoading();
                        await uploadPhotosAndSaveData(
                          userId: userId,
                          personalPhoto: personalPhoto,
                          driverLicensePhotos: driverLicensePhoto,
                          idPhotos: iDPhoto,
                          context: context,
                        );
                      }
                      ref.read(loadingProvider.notifier).stopLoading();
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CertificatesDetails(role: role),
                        ),
                      );
                    }
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
                    child:
                        isLoading
                            ? Center(
                              child: SpinKitThreeBounce(
                                color: const Color.fromRGBO(231, 231, 231, 1),
                                size: width * 0.061,
                              ),
                            )
                            : Center(
                              child: Text(
                                'Next',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: width * 0.04,
                                  color:
                                      _allFilledOut(role)
                                          ? (darkMode
                                              ? const Color.fromARGB(
                                                255,
                                                0,
                                                0,
                                                0,
                                              )
                                              : const Color.fromARGB(
                                                255,
                                                255,
                                                255,
                                                255,
                                              ))
                                          : (darkMode
                                              ? const Color.fromARGB(
                                                132,
                                                0,
                                                0,
                                                0,
                                              )
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
