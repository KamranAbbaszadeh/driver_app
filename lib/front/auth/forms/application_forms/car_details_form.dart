import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/tools/image_picker.dart';
import 'package:driver_app/back/tools/loading_notifier.dart';
import 'package:driver_app/back/upload_files/vehicle_details/upload_vehicle_details_save.dart';
import 'package:driver_app/db/user_data/store_role.dart';
import 'package:driver_app/front/auth/waiting_page.dart';
import 'package:driver_app/back/tools/vehicle_type_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';

class CarDetailsForm extends ConsumerStatefulWidget {
  const CarDetailsForm({super.key});

  @override
  ConsumerState<CarDetailsForm> createState() => _CarDetailsFormState();
}

class _CarDetailsFormState extends ConsumerState<CarDetailsForm> {
  final ScrollController _scrollController = ScrollController();
  String error = "No Error Detected";

  final TextEditingController nameOfTheCarController = TextEditingController();
  late FocusNode nameOfTheCarFocusNode;
  bool isNameOfTheCarEmpty = false;

  final TextEditingController technicalPassportNumberController =
      TextEditingController();
  late FocusNode technicalPassportNumberFocusNode;
  List<Asset> technicalPassportNumberPhoto = <Asset>[];
  bool isTechnicalPassportNumberEmpty = false;

  final TextEditingController chassisNumberController = TextEditingController();
  late FocusNode chassisNumberFocusNode;
  dynamic chassisNumberPhoto;
  bool isChassisNumberEmpty = false;

  final TextEditingController yearOfTheCarController = TextEditingController();
  late FocusNode yearOfTheCarFocusNode;
  bool isYearOfTheCarEmpty = false;

  final TextEditingController vehicleCategoryController =
      TextEditingController();
  late FocusNode vehicleCategoryFocusNode;
  bool isVehicleCategoryEmpty = false;
  Set<String> selectedVehicleCategory = {};

  final TextEditingController seatNumbersController = TextEditingController();
  late FocusNode seatNumbersFocusNode;
  bool isSeatNumbersEmpty = false;

  final TextEditingController vehicleRegistrationNumberController =
      TextEditingController();
  late FocusNode vehicleRegistrationNumberFocusNode;
  bool isVehicleRegistrationNumberEmpty = false;

  List<Asset> carsPhoto = <Asset>[];

  void _isEmpty(TextEditingController controller, String fieldName) {
    setState(() {
      if (controller.text.isEmpty) {
        if (fieldName == 'Name of the car') {
          isNameOfTheCarEmpty = true;
        } else if (fieldName == 'Technical Passport Number') {
          isTechnicalPassportNumberEmpty = true;
        } else if (fieldName == 'Chassis Number') {
          isChassisNumberEmpty = true;
        } else if (fieldName == 'Year of the car') {
          isYearOfTheCarEmpty = true;
        } else if (fieldName == 'Vehicle Category') {
          isVehicleCategoryEmpty = true;
        } else if (fieldName == 'Seat Number') {
          isSeatNumbersEmpty = true;
        } else if (fieldName == 'Vehicle Registration Number') {
          isVehicleRegistrationNumberEmpty = true;
        }
      } else {
        if (fieldName == 'Name of the car') {
          isNameOfTheCarEmpty = false;
        } else if (fieldName == 'Technical Passport Number') {
          isTechnicalPassportNumberEmpty = false;
        } else if (fieldName == 'Chassis Number') {
          isChassisNumberEmpty = false;
        } else if (fieldName == 'Year of the car') {
          isYearOfTheCarEmpty = false;
        } else if (fieldName == 'Vehicle Category') {
          isVehicleCategoryEmpty = false;
        } else if (fieldName == 'Seat Number') {
          isSeatNumbersEmpty = false;
        } else if (fieldName == 'Vehicle Registration Number') {
          isVehicleRegistrationNumberEmpty = false;
        }
      }
    });
  }

  bool _showTitle = false;
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

    nameOfTheCarFocusNode = FocusNode();
    technicalPassportNumberFocusNode = FocusNode();
    chassisNumberFocusNode = FocusNode();
    yearOfTheCarFocusNode = FocusNode();
    vehicleCategoryFocusNode = FocusNode();
    seatNumbersFocusNode = FocusNode();
    vehicleRegistrationNumberFocusNode = FocusNode();

    nameOfTheCarFocusNode.addListener(() {
      if (!nameOfTheCarFocusNode.hasFocus) {
        _isEmpty(nameOfTheCarController, 'Name of the car');
      }
    });
    technicalPassportNumberFocusNode.addListener(() {
      if (!technicalPassportNumberFocusNode.hasFocus) {
        _isEmpty(
          technicalPassportNumberController,
          'Technical Passport Number',
        );
      }
    });
    chassisNumberFocusNode.addListener(() {
      if (!chassisNumberFocusNode.hasFocus) {
        _isEmpty(chassisNumberController, 'Chassis Number');
      }
    });
    yearOfTheCarFocusNode.addListener(() {
      if (!yearOfTheCarFocusNode.hasFocus) {
        _isEmpty(yearOfTheCarController, 'Year of the car');
      }
    });
    vehicleCategoryFocusNode.addListener(() {
      if (!vehicleCategoryFocusNode.hasFocus) {
        _isEmpty(vehicleCategoryController, 'Vehicle Category');
      }
    });
    seatNumbersFocusNode.addListener(() {
      if (!seatNumbersFocusNode.hasFocus) {
        _isEmpty(seatNumbersController, 'Seat Number');
      }
    });
    vehicleRegistrationNumberFocusNode.addListener(() {
      if (!vehicleRegistrationNumberFocusNode.hasFocus) {
        _isEmpty(
          vehicleRegistrationNumberController,
          'Vehicle Registration Number',
        );
      }
    });

    nameOfTheCarController.addListener(() {
      setState(() {});
    });
    technicalPassportNumberController.addListener(() {
      setState(() {});
    });
    chassisNumberController.addListener(() {
      setState(() {});
    });
    yearOfTheCarController.addListener(() {
      setState(() {});
    });
    vehicleCategoryController.addListener(() {
      setState(() {});
    });
    seatNumbersController.addListener(() {
      setState(() {});
    });
    vehicleRegistrationNumberController.addListener(() {
      setState(() {});
    });
  }

  bool _allFilledOut() {
    if (nameOfTheCarController.text.isNotEmpty &&
        technicalPassportNumberController.text.isNotEmpty &&
        chassisNumberController.text.isNotEmpty &&
        yearOfTheCarController.text.isNotEmpty &&
        vehicleCategoryController.text.isNotEmpty &&
        seatNumbersController.text.isNotEmpty &&
        vehicleRegistrationNumberController.text.isNotEmpty &&
        chassisNumberPhoto != null &&
        technicalPassportNumberPhoto.isNotEmpty &&
        carsPhoto.isNotEmpty) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    nameOfTheCarFocusNode.dispose();
    technicalPassportNumberFocusNode.dispose();
    chassisNumberFocusNode.dispose();
    yearOfTheCarFocusNode.dispose();
    vehicleCategoryFocusNode.dispose();
    seatNumbersFocusNode.dispose();
    vehicleRegistrationNumberFocusNode.dispose();

    nameOfTheCarController.dispose();
    technicalPassportNumberController.dispose();
    chassisNumberController.dispose();
    yearOfTheCarController.dispose();
    vehicleCategoryController.dispose();
    seatNumbersController.dispose();
    vehicleRegistrationNumberController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(roleProvider);
    String numOfPages = role == 'Guide' ? '3/3' : '4/4';
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final isLoading = ref.watch(loadingProvider);

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
            '$numOfPages Your Vehicle, Your Partnership',
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
                  '$numOfPages Your Vehicle, Your Partnership',
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
                  'Let\'s get to know your vehicle! Share the details to ensure you\'re fully equipped to provide reliable and safe service.',
                ),
                SizedBox(height: height * 0.015),
                //Name of the car
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isNameOfTheCarEmpty
                              ? Color.fromARGB(255, 244, 92, 54)
                              : nameOfTheCarFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: nameOfTheCarFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          nameOfTheCarFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(nameOfTheCarController, 'Name of the vehicle');
                        setState(() {
                          nameOfTheCarFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: nameOfTheCarFocusNode,
                      onSubmitted: (_) {
                        nameOfTheCarFocusNode.unfocus();
                      },
                      controller: nameOfTheCarController,
                      decoration: InputDecoration(
                        suffixIcon:
                            nameOfTheCarFocusNode.hasFocus
                                ? nameOfTheCarController.text.isEmpty
                                    ? Icon(
                                      Icons.cancel_outlined,
                                      size: width * 0.076,
                                      color: Color.fromARGB(255, 158, 158, 158),
                                    )
                                    : IconButton(
                                      onPressed: () {
                                        nameOfTheCarController.clear();
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
                        labelText: 'Name of the car',
                        hintText: 'eg. Mercedes Benz, E220',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isNameOfTheCarEmpty
                                  ? Color.fromARGB(255, 244, 92, 54)
                                  : nameOfTheCarFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isNameOfTheCarEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //Car photos picker
                Row(
                  children: [
                    Text('Please Upload Photos of vehicle'),
                    Spacer(),
                    IconButton(
                      onPressed: () async {
                        var resultList = await loadAssets(
                          error: error,
                          maxNumOfPhotos: 12,
                          minNumOfPhotos: 4,
                        );

                        setState(() {
                          carsPhoto = resultList;
                        });
                        if (context.mounted) {
                          FocusScope.of(
                            context,
                          ).requestFocus(technicalPassportNumberFocusNode);
                        }
                      },
                      icon: Icon(Icons.add),
                    ),
                  ],
                ),
                //Car photos display
                carsPhoto.isEmpty
                    ? SizedBox.shrink()
                    : Container(
                      width: width,
                      height: height / 5,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(113, 80, 79, 79),
                        borderRadius: BorderRadius.circular(width * 0.019),
                      ),
                      padding: EdgeInsets.all(width * 0.02),
                      child: buildGridView(
                        images: carsPhoto,
                        height: height,
                        width: width,
                      ),
                    ),
                SizedBox(height: height * 0.015),
                //Technical Passport Number
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isTechnicalPassportNumberEmpty
                              ? Color.fromARGB(255, 244, 92, 54)
                              : technicalPassportNumberFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        technicalPassportNumberFocusNode.hasFocus
                            ? 0
                            : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          technicalPassportNumberFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(
                          technicalPassportNumberController,
                          'Technical Passport Number',
                        );
                        setState(() {
                          technicalPassportNumberFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: technicalPassportNumberFocusNode,
                      onSubmitted: (_) {
                        technicalPassportNumberFocusNode.unfocus();
                      },
                      controller: technicalPassportNumberController,
                      decoration: InputDecoration(
                        suffixIcon:
                            technicalPassportNumberFocusNode.hasFocus
                                ? technicalPassportNumberController.text.isEmpty
                                    ? Icon(
                                      Icons.cancel_outlined,
                                      size: width * 0.076,
                                      color: Color.fromARGB(255, 158, 158, 158),
                                    )
                                    : IconButton(
                                      onPressed: () {
                                        technicalPassportNumberController
                                            .clear();
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
                        labelText: 'Technical Passort Number',
                        hintText: 'Vehicle Registration Certificate',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isTechnicalPassportNumberEmpty
                                  ? Color.fromARGB(255, 244, 92, 54)
                                  : technicalPassportNumberFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isTechnicalPassportNumberEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //Technical Passport photos picker
                Row(
                  children: [
                    Text('Please Upload Photos of Technical Passport'),
                    Spacer(),
                    IconButton(
                      onPressed: () async {
                        var resultList = await loadAssets(
                          error: error,
                          maxNumOfPhotos: 2,
                          minNumOfPhotos: 2,
                        );
                        setState(() {
                          technicalPassportNumberPhoto = resultList;
                        });

                        if (context.mounted) {
                          FocusScope.of(
                            context,
                          ).requestFocus(chassisNumberFocusNode);
                        }
                      },
                      icon: Icon(Icons.add),
                    ),
                  ],
                ),
                //Technical passport photos display
                technicalPassportNumberPhoto.isEmpty
                    ? SizedBox.shrink()
                    : Container(
                      width: width,
                      height: height / 5,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(113, 80, 79, 79),
                        borderRadius: BorderRadius.circular(width * 0.019),
                      ),
                      padding: EdgeInsets.all(width * 0.02),
                      child: buildGridView(
                        images: technicalPassportNumberPhoto,
                        height: height,
                        width: width,
                      ),
                    ),
                SizedBox(height: height * 0.015),
                //Chassis Number
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isChassisNumberEmpty
                              ? Color.fromARGB(255, 244, 92, 54)
                              : chassisNumberFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: chassisNumberFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          chassisNumberFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(chassisNumberController, 'Chassis Number');
                        setState(() {
                          chassisNumberFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: chassisNumberFocusNode,
                      onEditingComplete: () {
                        chassisNumberFocusNode.unfocus();
                      },
                      controller: chassisNumberController,
                      decoration: InputDecoration(
                        suffixIcon:
                            chassisNumberFocusNode.hasFocus
                                ? chassisNumberController.text.isEmpty
                                    ? Icon(
                                      Icons.cancel_outlined,
                                      size: width * 0.076,
                                      color: Color.fromARGB(255, 158, 158, 158),
                                    )
                                    : IconButton(
                                      onPressed: () {
                                        chassisNumberController.clear();
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
                        labelText: 'Chassis Number',
                        hintText: 'Vehicle Identification Number',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isChassisNumberEmpty
                                  ? Color.fromARGB(255, 244, 92, 54)
                                  : chassisNumberFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isChassisNumberEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //Chasis Number photos picker
                Row(
                  children: [
                    Text('Please Upload Photos of Chassis Number'),
                    Spacer(),
                    IconButton(
                      onPressed: () async {
                        var resultList = await loadAssets(
                          error: error,
                          maxNumOfPhotos: 1,
                          minNumOfPhotos: 1,
                        );
                        setState(() {
                          chassisNumberPhoto = resultList.first;
                        });
                        if (context.mounted) {
                          FocusScope.of(
                            context,
                          ).requestFocus(vehicleRegistrationNumberFocusNode);
                        }
                      },
                      icon: Icon(Icons.add),
                    ),
                  ],
                ),
                //Chassis Number photos display
                chassisNumberPhoto == null
                    ? SizedBox.shrink()
                    : Container(
                      width: width,
                      height: height / 5,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(113, 80, 79, 79),
                        borderRadius: BorderRadius.circular(width * 0.019),
                      ),
                      padding: EdgeInsets.all(width * 0.02),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: AssetThumb(
                          asset: chassisNumberPhoto,
                          width: (width * 0.254).toInt(),
                          height: (height * 0.117).toInt(),
                        ),
                      ),
                    ),
                SizedBox(height: height * 0.015),
                //Vehicle Registration Number
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isVehicleRegistrationNumberEmpty
                              ? Color.fromARGB(255, 244, 92, 54)
                              : vehicleRegistrationNumberFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        vehicleRegistrationNumberFocusNode.hasFocus
                            ? 0
                            : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          vehicleRegistrationNumberFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(
                          vehicleRegistrationNumberController,
                          'Vehicle Registration Number',
                        );
                        setState(() {
                          vehicleRegistrationNumberFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: vehicleRegistrationNumberFocusNode,
                      onEditingComplete: () {
                        vehicleRegistrationNumberFocusNode.unfocus();
                        FocusScope.of(
                          context,
                        ).requestFocus(yearOfTheCarFocusNode);
                      },
                      controller: vehicleRegistrationNumberController,
                      decoration: InputDecoration(
                        suffixIcon:
                            vehicleRegistrationNumberFocusNode.hasFocus
                                ? vehicleRegistrationNumberController
                                        .text
                                        .isEmpty
                                    ? Icon(
                                      Icons.cancel_outlined,
                                      size: width * 0.076,
                                      color: Color.fromARGB(255, 158, 158, 158),
                                    )
                                    : IconButton(
                                      onPressed: () {
                                        vehicleRegistrationNumberController
                                            .clear();
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
                        labelText: 'Vehicle Registration Number',
                        hintText: 'eg. 99-AZ-999',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isVehicleRegistrationNumberEmpty
                                  ? Color.fromARGB(255, 244, 92, 54)
                                  : vehicleRegistrationNumberFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isVehicleRegistrationNumberEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //Year of The Car
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isYearOfTheCarEmpty
                              ? Color.fromARGB(255, 244, 92, 54)
                              : yearOfTheCarFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: yearOfTheCarFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          yearOfTheCarFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(yearOfTheCarController, 'Year of the car');
                        setState(() {
                          yearOfTheCarFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: yearOfTheCarFocusNode,
                      onEditingComplete: () {
                        yearOfTheCarFocusNode.unfocus();
                        FocusScope.of(
                          context,
                        ).requestFocus(vehicleCategoryFocusNode);
                      },
                      controller: yearOfTheCarController,
                      decoration: InputDecoration(
                        suffixIcon:
                            yearOfTheCarFocusNode.hasFocus
                                ? yearOfTheCarController.text.isEmpty
                                    ? Icon(
                                      Icons.cancel_outlined,
                                      size: width * 0.076,
                                      color: Color.fromARGB(255, 158, 158, 158),
                                    )
                                    : IconButton(
                                      onPressed: () {
                                        yearOfTheCarController.clear();
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
                        labelText: 'Year of the car',
                        hintText: DateTime.now().year.toString(),
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isYearOfTheCarEmpty
                                  ? Color.fromARGB(255, 244, 92, 54)
                                  : yearOfTheCarFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isYearOfTheCarEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //Vehicle Type
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isVehicleCategoryEmpty
                              ? Color.fromARGB(255, 244, 92, 54)
                              : vehicleCategoryFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        vehicleCategoryFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () async {
                        setState(() {
                          vehicleCategoryFocusNode.requestFocus();
                        });
                        await showVehicleTypePicker(
                          context,
                          selectedVehicleCategory,
                        );
                        vehicleCategoryController.text = selectedVehicleCategory
                            .join(', ');
                        _isEmpty(vehicleCategoryController, 'Vehicle Category');
                      },
                      onTapOutside: (_) {
                        _isEmpty(vehicleCategoryController, 'Vehicle Category');
                        setState(() {
                          vehicleCategoryFocusNode.unfocus();
                        });
                      },
                      readOnly: true,
                      focusNode: vehicleCategoryFocusNode,
                      onEditingComplete: () {
                        vehicleCategoryFocusNode.unfocus();
                        FocusScope.of(
                          context,
                        ).requestFocus(seatNumbersFocusNode);
                      },
                      controller: vehicleCategoryController,
                      decoration: InputDecoration(
                        suffixIcon: Icon(
                          Icons.chevron_right_rounded,
                          size: width * 0.085,
                        ),
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
                        labelText: 'Vehicle Type',
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isVehicleCategoryEmpty
                                  ? Color.fromARGB(255, 244, 92, 54)
                                  : vehicleCategoryFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isVehicleCategoryEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //Seat Number
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isSeatNumbersEmpty
                              ? Color.fromARGB(255, 244, 92, 54)
                              : seatNumbersFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: seatNumbersFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          seatNumbersFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(seatNumbersController, 'Seat Number');
                        setState(() {
                          seatNumbersFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: seatNumbersFocusNode,
                      onEditingComplete: () {
                        seatNumbersFocusNode.unfocus();
                      },
                      controller: seatNumbersController,
                      decoration: InputDecoration(
                        suffixIcon:
                            seatNumbersFocusNode.hasFocus
                                ? seatNumbersController.text.isEmpty
                                    ? Icon(
                                      Icons.cancel_outlined,
                                      size: width * 0.076,
                                      color: Color.fromARGB(255, 158, 158, 158),
                                    )
                                    : IconButton(
                                      onPressed: () {
                                        seatNumbersController.clear();
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
                        labelText: 'Seat Number',
                        hintText: 'Mention amout of car\'s seats',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isSeatNumbersEmpty
                                  ? Color.fromARGB(255, 244, 92, 54)
                                  : seatNumbersFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSeatNumbersEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.025),
                GestureDetector(
                  onTap: () async {
                    if (_allFilledOut()) {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        ref.read(loadingProvider.notifier).startLoading();
                        await uploadVehicleDetailsAndSave(
                          userId: userId,
                          carName: nameOfTheCarController.text,
                          vehiclePhoto: carsPhoto,
                          technicalPassportNumber:
                              technicalPassportNumberController.text,
                          technicalPassport: technicalPassportNumberPhoto,
                          chassisNumber: chassisNumberController.text,
                          chassisPhoto: chassisNumberPhoto,
                          vehicleRegistrationNumber:
                              vehicleRegistrationNumberController.text,
                          vehiclesYear: yearOfTheCarController.text,
                          vehicleType: vehicleCategoryController.text,
                          seatNumber: seatNumbersController.text,
                          context: context,
                        );
                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(userId)
                            .update({
                              'Personal & Car Details Form':
                                  'APPLICATION RECEIVED',
                            });
                        ref.read(loadingProvider.notifier).stopLoading();
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WaitingPage(),
                            ),
                          );
                        }
                      }
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
                    child:
                        isLoading
                            ? Center(
                              child: SpinKitThreeBounce(
                                color: Color.fromRGBO(231, 231, 231, 1),
                                size: width * 0.061,
                              ),
                            )
                            : Center(
                              child: Text(
                                'Submit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: width * 0.04,
                                  color:
                                      _allFilledOut()
                                          ? (darkMode
                                              ? Color.fromARGB(255, 0, 0, 0)
                                              : Color.fromARGB(
                                                255,
                                                255,
                                                255,
                                                255,
                                              ))
                                          : (darkMode
                                              ? Color.fromARGB(132, 0, 0, 0)
                                              : Color.fromARGB(
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
                SizedBox(height: height * 0.058),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
