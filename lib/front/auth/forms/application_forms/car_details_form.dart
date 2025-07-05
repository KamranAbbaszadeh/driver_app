import 'package:onemoretour/back/tools/image_picker.dart';
import 'package:onemoretour/back/upload_files/vehicle_details/upload_vehicle_details_save.dart';
import 'package:onemoretour/back/upload_files/vehicle_details/vehicle_details_provider.dart';
import 'package:onemoretour/db/user_data/store_role.dart';
import 'package:onemoretour/back/tools/vehicle_type_picker.dart';
import 'package:onemoretour/front/auth/forms/application_forms/upper_case_text_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onemoretour/front/tools/photo_picker_with_display.dart';
import 'package:onemoretour/front/tools/signle_photo_picker_with_display.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// Validators
bool validateCarName(String value) {
  return RegExp(r"^[A-Za-z0-9\s\-,.]{2,50}$").hasMatch(value);
}

bool validateTechnicalPassportNumber(String value) {
  return RegExp(r"^[A-Z0-9]{6,12}$").hasMatch(value);
}

bool validateChassisNumber(String value) {
  return RegExp(r"^[A-Z0-9]{17}$").hasMatch(value);
}

bool validateVehicleRegistrationNumber(String value) {
  return RegExp(r"^\d{2}-[A-Z]{2}-\d{3}$").hasMatch(value);
}

bool validateYearOfCar(String value) {
  if (value.isEmpty) return false;
  int? year = int.tryParse(value);
  if (year == null) return false;
  int currentYear = DateTime.now().year;
  return year >= 1950 && year <= currentYear;
}

bool validateSeatNumber(String value) {
  if (value.isEmpty) return false;
  int? seats = int.tryParse(value);
  if (seats == null) return false;
  return seats >= 1 && seats <= 99;
}

class CarDetailsForm extends ConsumerStatefulWidget {
  final String vehicleType;
  final bool multiSelection;
  final void Function(Map<String, dynamic>) onFormSubmit;
  final Map<String, dynamic>? initialData;
  final bool isDeclined;
  final Future<void> Function(String url)? onDeleteRemotePhoto;

  const CarDetailsForm({
    super.key,
    required this.onFormSubmit,
    required this.vehicleType,
    required this.multiSelection,
    this.initialData,
    required this.isDeclined,
    required this.onDeleteRemotePhoto,
  });

  @override
  ConsumerState<CarDetailsForm> createState() => CarDetailsFormState();
}

class CarDetailsFormState extends ConsumerState<CarDetailsForm> {
  Future<void> _updateVehicleDetailsProvider() async {
    final updatedData = {
      'Vehicle Name': nameOfTheCarController.text,
      'Vehicle Photos Local': carsPhoto.map((x) => x.path).toList(),
      'Technical Passport Photos Local':
          technicalPassportNumberPhoto.map((x) => x.path).toList(),
      'Chassis Number Photo Local': chassisNumberPhoto?.path ?? '',
      'Technical Passport Number': technicalPassportNumberController.text,
      'Chassis Number': chassisNumberController.text,
      'Vehicle Registration Number': vehicleRegistrationNumberController.text,
      'Vehicle\'s Year': yearOfTheCarController.text,
      'Vehicle\'s Type': vehicleCategoryController.text,
      'Seat Number': int.tryParse(seatNumbersController.text) ?? 0,
    };

    final vehicleDetails = ref.read(vehicleDetailsProvider);
    final newKey =
        '${vehicleCategoryController.text} - ${vehicleRegistrationNumberController.text}';

    ref.read(vehicleDetailsProvider.notifier).update((state) {
      final updated = Map<String, dynamic>.from(state);
      updated[newKey] = {...?vehicleDetails[newKey], ...updatedData};
      return updated;
    });
  }

  final ScrollController _scrollController = ScrollController();
  String error = "No Error Detected";

  final TextEditingController nameOfTheCarController = TextEditingController();
  late FocusNode nameOfTheCarFocusNode;
  bool isNameOfTheCarEmpty = false;

  final TextEditingController technicalPassportNumberController =
      TextEditingController();
  late FocusNode technicalPassportNumberFocusNode;
  List<XFile> technicalPassportNumberPhoto = <XFile>[];
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

  List<XFile> carsPhoto = <XFile>[];

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
    nameOfTheCarFocusNode = FocusNode();
    technicalPassportNumberFocusNode = FocusNode();
    chassisNumberFocusNode = FocusNode();
    yearOfTheCarFocusNode = FocusNode();
    vehicleCategoryFocusNode = FocusNode();
    seatNumbersFocusNode = FocusNode();
    vehicleRegistrationNumberFocusNode = FocusNode();

    // Load initialData if provided
    if (widget.initialData != null) {
      final data = widget.initialData!;

      nameOfTheCarController.text = data['Vehicle Name'] ?? '';
      technicalPassportNumberController.text =
          data['Technical Passport Number'] ?? '';
      chassisNumberController.text = data['Chassis Number'] ?? '';
      yearOfTheCarController.text = data['Vehicle\'s Year'] ?? '';
      vehicleCategoryController.text = data['Vehicle\'s Type'] ?? '';
      selectedVehicleCategory = {data['Vehicle\'s Type'] ?? ''};
      seatNumbersController.text = (data['Seat Number']?.toString() ?? '');
      vehicleRegistrationNumberController.text =
          data['Vehicle Registration Number'] ?? '';

      carsPhoto =
          (data['Vehicle Photos Local'] as List<dynamic>? ?? [])
              .map((url) => XFile(url))
              .toList();

      technicalPassportNumberPhoto =
          (data['Technical Passport Photos Local'] as List<dynamic>? ?? [])
              .map((url) => XFile(url))
              .toList();

      final chassisPhotoUrl = data['Chassis Number Photo Local'] as String?;
      chassisNumberPhoto =
          chassisPhotoUrl != null ? XFile(chassisPhotoUrl) : null;
    }
    if (widget.multiSelection) return;

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

    if (!widget.multiSelection) {
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
        _saveTempData();
      });
      technicalPassportNumberController.addListener(() {
        setState(() {});
        _saveTempData();
      });
      chassisNumberController.addListener(() {
        setState(() {});
        _saveTempData();
      });
      yearOfTheCarController.addListener(() {
        setState(() {});
        _saveTempData();
      });
      vehicleCategoryController.addListener(() {
        setState(() {});
        _saveTempData();
      });
      seatNumbersController.addListener(() {
        setState(() {});
        _saveTempData();
      });
      vehicleRegistrationNumberController.addListener(() {
        setState(() {});
        _saveTempData();
      });

      _loadTempData();
      _loadTempPhotos();
    }
  }

  Future<void> _saveTempPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = widget.vehicleType.toLowerCase().replaceAll(' ', '_');

    if (widget.multiSelection) {
      await prefs.setStringList(
        '${prefix}_carPhotos',
        carsPhoto.map((x) => x.path).toList(),
      );
      await prefs.setStringList(
        '${prefix}_techPassportPhotos',
        technicalPassportNumberPhoto.map((x) => x.path).toList(),
      );
      if (chassisNumberPhoto != null) {
        await prefs.setString(
          '${prefix}_chassisPhoto',
          chassisNumberPhoto.path,
        );
      }
    } else {
      await prefs.setStringList(
        'carPhotos',
        carsPhoto.map((x) => x.path).toList(),
      );
      await prefs.setStringList(
        'techPassportPhotos',
        technicalPassportNumberPhoto.map((x) => x.path).toList(),
      );
      if (chassisNumberPhoto != null) {
        await prefs.setString('chassisPhoto', chassisNumberPhoto.path);
      }
    }
  }

  Future<void> _loadTempPhotos() async {
    if (widget.multiSelection) return;
    final prefs = await SharedPreferences.getInstance();
    final carPaths = prefs.getStringList('carPhotos') ?? [];
    final techPaths = prefs.getStringList('techPassportPhotos') ?? [];
    final chassisPath = prefs.getString('chassisPhoto');

    setState(() {
      carsPhoto =
          carPaths
              .where((path) => path.isNotEmpty)
              .map((path) => XFile(path))
              .toList();
      technicalPassportNumberPhoto =
          techPaths
              .where((path) => path.isNotEmpty)
              .map((path) => XFile(path))
              .toList();
      if (chassisPath != null && chassisPath.isNotEmpty) {
        chassisNumberPhoto = XFile(chassisPath);
      }
    });
  }

  Future<void> clearTempPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = widget.vehicleType.toLowerCase().replaceAll(' ', '_');

    if (widget.multiSelection) {
      await prefs.remove('${prefix}_carPhotos');
      await prefs.remove('${prefix}_techPassportPhotos');
      await prefs.remove('${prefix}_chassisPhoto');
    } else {
      await prefs.remove('carPhotos');
      await prefs.remove('techPassportPhotos');
      await prefs.remove('chassisPhoto');
    }
  }

  bool allFilledOut() {
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

  Future<void> _saveTempData() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = widget.vehicleType.toLowerCase().replaceAll(' ', '_');

    if (widget.multiSelection) {
      await prefs.setString('${prefix}_carName', nameOfTheCarController.text);
      await prefs.setString('${prefix}_seatNumber', seatNumbersController.text);
      await prefs.setString('${prefix}_year', yearOfTheCarController.text);
      await prefs.setString(
        '${prefix}_vehicleType',
        vehicleCategoryController.text,
      );
      await prefs.setString(
        '${prefix}_technicalPassport',
        technicalPassportNumberController.text,
      );
      await prefs.setString(
        '${prefix}_chassisNumber',
        chassisNumberController.text,
      );
      await prefs.setString(
        '${prefix}_registrationNumber',
        vehicleRegistrationNumberController.text,
      );
    } else {
      await prefs.setString('carName', nameOfTheCarController.text);
      await prefs.setString('seatNumber', seatNumbersController.text);
      await prefs.setString('year', yearOfTheCarController.text);
      await prefs.setString('vehicleType', vehicleCategoryController.text);
      await prefs.setString(
        'technicalPassport',
        technicalPassportNumberController.text,
      );
      await prefs.setString('chassisNumber', chassisNumberController.text);
      await prefs.setString(
        'registrationNumber',
        vehicleRegistrationNumberController.text,
      );
    }
  }

  Future<void> _loadTempData() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = widget.vehicleType.toLowerCase().replaceAll(' ', '_');

    if (widget.multiSelection) {
      nameOfTheCarController.text = prefs.getString('${prefix}_carName') ?? '';
      seatNumbersController.text =
          prefs.getString('${prefix}_seatNumber') ?? '';
      yearOfTheCarController.text = prefs.getString('${prefix}_year') ?? '';
      vehicleCategoryController.text =
          prefs.getString('${prefix}_vehicleType') ?? '';
      technicalPassportNumberController.text =
          prefs.getString('${prefix}_technicalPassport') ?? '';
      chassisNumberController.text =
          prefs.getString('${prefix}_chassisNumber') ?? '';
      vehicleRegistrationNumberController.text =
          prefs.getString('${prefix}_registrationNumber') ?? '';
    } else {
      nameOfTheCarController.text = prefs.getString('carName') ?? '';
      seatNumbersController.text = prefs.getString('seatNumber') ?? '';
      yearOfTheCarController.text = prefs.getString('year') ?? '';
      vehicleCategoryController.text = prefs.getString('vehicleType') ?? '';
      technicalPassportNumberController.text =
          prefs.getString('technicalPassport') ?? '';
      chassisNumberController.text = prefs.getString('chassisNumber') ?? '';
      vehicleRegistrationNumberController.text =
          prefs.getString('registrationNumber') ?? '';
    }
  }

  Future<void> clearTempData() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = widget.vehicleType.toLowerCase().replaceAll(' ', '_');

    if (widget.multiSelection) {
      await prefs.remove('${prefix}_carName');
      await prefs.remove('${prefix}_seatNumber');
      await prefs.remove('${prefix}_year');
      await prefs.remove('${prefix}_vehicleType');
      await prefs.remove('${prefix}_technicalPassport');
      await prefs.remove('${prefix}_chassisNumber');
      await prefs.remove('${prefix}_registrationNumber');
    } else {
      await prefs.remove('carName');
      await prefs.remove('seatNumber');
      await prefs.remove('year');
      await prefs.remove('vehicleType');
      await prefs.remove('technicalPassport');
      await prefs.remove('chassisNumber');
      await prefs.remove('registrationNumber');
    }
  }

  Future<Map<String, dynamic>?> prepareVehicleFormData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final storageRef = FirebaseStorage.instance.ref();

    List<String> vehiclePhotosUrls = await uploadMultiplePhotos(
      storageRef: storageRef,
      userId: userId,
      files: carsPhoto,
      folderName: 'Vehicle Photos',
    );

    List<String> technicalPassportUrls = await uploadMultiplePhotos(
      storageRef: storageRef,
      userId: userId,
      files: technicalPassportNumberPhoto,
      folderName: 'Technical Passport',
    );

    String chassisNumberUrl = await uploadSinglePhoto(
      storageRef: storageRef,
      userID: userId,
      file: chassisNumberPhoto,
      folderName: 'Chassis Number',
    );

    int seatNumberNum = int.parse(seatNumbersController.text);

    return {
      'Vehicle Name': nameOfTheCarController.text,
      'Vehicle Photos': vehiclePhotosUrls,
      'Technical Passport Number': technicalPassportNumberController.text,
      'Technical Passport Photos': technicalPassportUrls,
      'Chassis Number': chassisNumberController.text,
      'Chassis Number Photo': chassisNumberUrl,
      'Vehicle Registration Number': vehicleRegistrationNumberController.text,
      'Vehicle\'s Year': yearOfTheCarController.text,
      'Vehicle\'s Type': vehicleCategoryController.text,
      'Seat Number': seatNumberNum,
      "isApproved": false,
    };
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
    final roleDetails = ref.watch(roleProvider);
    final isRegistered = roleDetails?['isRegistered'] ?? false;
    String numOfPages = isRegistered ? "" : '4/4 ';
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: widget.multiSelection,
      child: Scaffold(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: widget.multiSelection,
          backgroundColor: darkMode ? Colors.black : Colors.white,
          surfaceTintColor: darkMode ? Colors.black : Colors.white,
          leading:
              widget.multiSelection
                  ? IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    hoverColor: Colors.transparent,
                    icon: Icon(
                      Icons.arrow_circle_left_rounded,
                      size: width * 0.1,
                      color: Colors.grey.shade400,
                    ),
                  )
                  : SizedBox.shrink(),
          toolbarHeight: height * 0.1,
          title: AnimatedOpacity(
            opacity: _showTitle ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: Text(
              isRegistered
                  ? 'Add Another Vehicle to Expand Your Partnership'
                  : '${numOfPages}Your Vehicle, Your Partnership'.trimLeft(),
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
                    isRegistered
                        ? 'Add Another Vehicle to Expand Your Partnership'
                        : '${numOfPages}Your Vehicle, Your Partnership'
                            .trimLeft(),
                    textAlign: TextAlign.start,
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
                    isRegistered
                        ? 'You can register more vehicles to increase your service capacity and flexibility.'
                        : 'Let\'s get to know your vehicle! Share the details to ensure you\'re fully equipped to provide reliable and safe service.',
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
                      bottom:
                          nameOfTheCarFocusNode.hasFocus ? 0 : width * 0.025,
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
                          _isEmpty(
                            nameOfTheCarController,
                            'Name of the vehicle',
                          );
                          setState(() {
                            nameOfTheCarFocusNode.unfocus();
                          });
                        },
                        showCursor: true,
                        cursorHeight: height * 0.02,
                        cursorColor:
                            darkMode
                                ? Color.fromARGB(255, 1, 105, 170)
                                : Color.fromARGB(255, 0, 134, 179),
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
                                        color: Color.fromARGB(
                                          255,
                                          158,
                                          158,
                                          158,
                                        ),
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
                  //Car photos picker + display combined
                  PhotoPickerWithDisplay(
                    images: carsPhoto,
                    label: 'Please Upload Vehicle Photos',
                    onPick: () async {
                      final images =
                          await ImagePickerHelper.selectMultiplePhotos(
                            context: context,
                            maxImages: 6,
                            minImages: 3,
                          );
                      if (images != null) {
                        setState(() => carsPhoto.addAll(images));
                        await _saveTempPhotos();
                      }
                    },
                    onRemove: (index) async {
                      final photo = carsPhoto[index];
                      setState(() => carsPhoto.removeAt(index));
                      await _saveTempPhotos();
                      await _updateVehicleDetailsProvider();
                      if (photo.path.startsWith('https://') &&
                          widget.onDeleteRemotePhoto != null) {
                        await widget.onDeleteRemotePhoto!(photo.path);
                      }
                    },
                    darkMode: darkMode,
                    minPhotos: "3",
                    isDeclined: widget.isDeclined,
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
                        showCursor: true,
                        cursorHeight: height * 0.02,
                        cursorColor:
                            darkMode
                                ? Color.fromARGB(255, 1, 105, 170)
                                : Color.fromARGB(255, 0, 134, 179),
                        focusNode: technicalPassportNumberFocusNode,
                        onSubmitted: (_) {
                          technicalPassportNumberFocusNode.unfocus();
                        },
                        controller: technicalPassportNumberController,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Z0-9]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          suffixIcon:
                              technicalPassportNumberFocusNode.hasFocus
                                  ? technicalPassportNumberController
                                          .text
                                          .isEmpty
                                      ? Icon(
                                        Icons.cancel_outlined,
                                        size: width * 0.076,
                                        color: Color.fromARGB(
                                          255,
                                          158,
                                          158,
                                          158,
                                        ),
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
                  PhotoPickerWithDisplay(
                    images: technicalPassportNumberPhoto,
                    label: "Please Upload Photos of Technical Passport",
                    onPick: () async {
                      final images =
                          await ImagePickerHelper.selectMultiplePhotos(
                            context: context,
                            maxImages: 2,
                            minImages: 2,
                          );
                      if (images != null) {
                        setState(
                          () => technicalPassportNumberPhoto.addAll(images),
                        );
                        await _saveTempPhotos();
                      }
                    },
                    onRemove: (index) async {
                      final filteredTechPhotos =
                          technicalPassportNumberPhoto
                              .where((x) => x.path.isNotEmpty)
                              .toList();
                      final removedPhoto = filteredTechPhotos[index];
                      setState(() {
                        technicalPassportNumberPhoto.removeWhere(
                          (x) => x.path == removedPhoto.path,
                        );
                      });
                      await _saveTempPhotos();
                      await _updateVehicleDetailsProvider();
                      if (removedPhoto.path.startsWith('https://') &&
                          widget.onDeleteRemotePhoto != null) {
                        await widget.onDeleteRemotePhoto!(removedPhoto.path);
                      }
                    },
                    darkMode: darkMode,
                    minPhotos: "2",
                    isDeclined: widget.isDeclined,
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
                      bottom:
                          chassisNumberFocusNode.hasFocus ? 0 : width * 0.025,
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
                        showCursor: true,
                        cursorHeight: height * 0.02,
                        cursorColor:
                            darkMode
                                ? Color.fromARGB(255, 1, 105, 170)
                                : Color.fromARGB(255, 0, 134, 179),
                        focusNode: chassisNumberFocusNode,
                        onEditingComplete: () {
                          chassisNumberFocusNode.unfocus();
                        },
                        controller: chassisNumberController,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Z0-9]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          suffixIcon:
                              chassisNumberFocusNode.hasFocus
                                  ? chassisNumberController.text.isEmpty
                                      ? Icon(
                                        Icons.cancel_outlined,
                                        size: width * 0.076,
                                        color: Color.fromARGB(
                                          255,
                                          158,
                                          158,
                                          158,
                                        ),
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
                  SinglePhotoPickerWithDisplay(
                    image: chassisNumberPhoto,
                    label: "Please Upload Photos of Chassis Number",
                    onPick: () async {
                      final selected =
                          await ImagePickerHelper.selectSinglePhoto(
                            context: context,
                          );
                      if (selected == null) return;

                      setState(() => chassisNumberPhoto = selected);
                      await _saveTempPhotos();
                    },
                    onRemove: () async {
                      final removedPhoto = chassisNumberPhoto;
                      setState(() => chassisNumberPhoto = null);
                      await _saveTempPhotos();
                      await _updateVehicleDetailsProvider();
                      if (removedPhoto != null &&
                          removedPhoto.path.isNotEmpty &&
                          removedPhoto.path.startsWith('https://') &&
                          widget.onDeleteRemotePhoto != null) {
                        await widget.onDeleteRemotePhoto!(removedPhoto.path);
                      }
                    },
                    darkMode: darkMode,
                    minPhotos: "1",
                    isDeclined: widget.isDeclined,
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
                        showCursor: true,
                        cursorHeight: height * 0.02,
                        cursorColor:
                            darkMode
                                ? Color.fromARGB(255, 1, 105, 170)
                                : Color.fromARGB(255, 0, 134, 179),
                        focusNode: vehicleRegistrationNumberFocusNode,
                        onEditingComplete: () {
                          vehicleRegistrationNumberFocusNode.unfocus();
                          FocusScope.of(
                            context,
                          ).requestFocus(yearOfTheCarFocusNode);
                        },
                        controller: vehicleRegistrationNumberController,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Z0-9@#\$%^&*()_+=-]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          suffixIcon:
                              vehicleRegistrationNumberFocusNode.hasFocus
                                  ? vehicleRegistrationNumberController
                                          .text
                                          .isEmpty
                                      ? Icon(
                                        Icons.cancel_outlined,
                                        size: width * 0.076,
                                        color: Color.fromARGB(
                                          255,
                                          158,
                                          158,
                                          158,
                                        ),
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
                                    : vehicleRegistrationNumberFocusNode
                                        .hasFocus
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
                      bottom:
                          yearOfTheCarFocusNode.hasFocus ? 0 : width * 0.025,
                      left: width * 0.025,
                      top: width * 0.025,
                      right: width * 0.025,
                    ),
                    child: Center(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onChanged: (value) {
                          final year = int.tryParse(value);
                          if (year != null && year > DateTime.now().year) {
                            yearOfTheCarController.text =
                                DateTime.now().year.toString();
                            yearOfTheCarController
                                .selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: yearOfTheCarController.text.length,
                              ),
                            );
                          }
                        },
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
                        showCursor: true,
                        cursorHeight: height * 0.02,
                        cursorColor:
                            darkMode
                                ? Color.fromARGB(255, 1, 105, 170)
                                : Color.fromARGB(255, 0, 134, 179),
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
                                        color: Color.fromARGB(
                                          255,
                                          158,
                                          158,
                                          158,
                                        ),
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
                            singleSelection: true,
                          );
                          vehicleCategoryController
                              .text = selectedVehicleCategory.join(', ');
                          _isEmpty(
                            vehicleCategoryController,
                            'Vehicle Category',
                          );
                        },
                        onTapOutside: (_) {
                          _isEmpty(
                            vehicleCategoryController,
                            'Vehicle Category',
                          );
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
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                        showCursor: true,
                        cursorHeight: height * 0.02,
                        cursorColor:
                            darkMode
                                ? Color.fromARGB(255, 1, 105, 170)
                                : Color.fromARGB(255, 0, 134, 179),
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
                                        color: Color.fromARGB(
                                          255,
                                          158,
                                          158,
                                          158,
                                        ),
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
                      if (allFilledOut()) {
                        Map<String, dynamic> formData = {
                          'Vehicle Name': nameOfTheCarController.text,
                          'Technical Passport Number':
                              technicalPassportNumberController.text,
                          'Chassis Number': chassisNumberController.text,
                          'Vehicle Registration Number':
                              vehicleRegistrationNumberController.text,
                          'Vehicle\'s Year': yearOfTheCarController.text,
                          'Vehicle\'s Type': vehicleCategoryController.text,
                          'Seat Number': int.parse(seatNumbersController.text),
                          "isApproved": false,
                          'Vehicle Photos Local':
                              carsPhoto.map((x) => x.path).toList(),
                          'Technical Passport Photos Local':
                              technicalPassportNumberPhoto
                                  .map((x) => x.path)
                                  .toList(),
                          'Chassis Number Photo Local':
                              chassisNumberPhoto?.path ?? '',
                        };

                        widget.onFormSubmit(formData);
                        if (!widget.multiSelection) {
                          await clearTempPhotos();
                          await clearTempData();
                        }
                      }
                    },
                    child: Container(
                      width: width,
                      height: height * 0.058,
                      decoration: BoxDecoration(
                        color:
                            allFilledOut()
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
                          widget.multiSelection ? 'Done' : 'Submit',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: width * 0.04,
                            color:
                                allFilledOut()
                                    ? (darkMode
                                        ? Color.fromARGB(255, 0, 0, 0)
                                        : Color.fromARGB(255, 255, 255, 255))
                                    : (darkMode
                                        ? Color.fromARGB(132, 0, 0, 0)
                                        : Color.fromARGB(187, 255, 255, 255)),
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
      ),
    );
  }
}
