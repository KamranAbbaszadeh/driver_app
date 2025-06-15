import 'package:onemoretour/back/auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:onemoretour/back/tools/date_picker.dart';
import 'package:onemoretour/back/tools/gender_picker.dart';
import 'package:onemoretour/back/tools/language_picker.dart';
import 'package:onemoretour/back/tools/role_picker.dart';
import 'package:onemoretour/back/tools/validate_email.dart';
import 'package:flutter/services.dart';
import 'package:onemoretour/back/tools/vehicle_type_picker.dart';
import 'package:onemoretour/front/displayed_items/intermediate_page_for_forms.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onemoretour/front/intro/route_navigator.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationForm extends ConsumerStatefulWidget {
  const ApplicationForm({super.key});

  @override
  ConsumerState<ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends ConsumerState<ApplicationForm> {
  final user = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _languageController = TextEditingController();
  final _birthDayController = TextEditingController();
  final _experienceController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _roleController = TextEditingController();
  final _fathersNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Set<String> selectedLanguages = {};
  Set<String> selectedVehicleType = {};

  late FocusNode _firstNameFocusNode;
  late FocusNode _lastNameFocusNode;
  late FocusNode _emailFocusNode;
  late FocusNode _phoneNumberFocusNode;
  late FocusNode _languageFocusNode;
  late FocusNode _birthDayFocusNode;
  late FocusNode _experienceFocusNode;
  late FocusNode _vehicleTypeFocusNode;
  late FocusNode _roleFocusNode;
  late FocusNode _fathersNameFocusNode;
  late FocusNode _genderFocusNode;
  late FocusNode _passwordFocusNode;
  late FocusNode _confirmPasswordFocusNode;

  bool _showTitle = false;
  bool isValid = true;
  bool isPasswordValid = true;
  bool isPasswordConfirmed = true;
  bool isPhoneNumberValid = true;
  bool isChecked = false;
  bool isTapped = false;

  String passwordValidationString = '';
  int characterCount = 0;

  bool isFirstNameEmpty = false;
  bool isLastNameEmpty = false;
  bool isEmailEmpty = false;
  bool isPhoneNumberEmpty = false;
  bool isLanguageEmpty = false;
  bool isBirthDayEmpty = false;
  bool isExperienceEmpty = false;
  bool isVehicleTypeEmpty = false;
  bool isRoleEmpty = false;
  bool isFathersNameEmpty = false;
  bool isGenderEmpty = false;
  bool isConfirmPasswordEmpty = false;
  bool passwordObscure = true;
  bool confirmPasswordObscure = true;

  bool validateName(String value) {
    return RegExp(r"^[a-zA-Zа-яА-Я\s]+$").hasMatch(value);
  }

  bool validatePhoneNumber(String value) {
    return RegExp(r"^\+\d{12,}$").hasMatch(value);
  }

  bool validateExperience(String value) {
    return RegExp(r"^\d+$").hasMatch(value) && int.parse(value) > 0;
  }

  void _validateEmail(String value) {
    setState(() {
      isEmailEmpty = value.isEmpty;
      isValid = validateEmail(value);
    });
  }

  String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 8) {
      setState(() {
        isPasswordValid = false;
      });
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      setState(() {
        isPasswordValid = false;
      });
      return 'Password must include at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      setState(() {
        isPasswordValid = false;
      });
      return 'Password must include at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      setState(() {
        isPasswordValid = false;
      });
      return 'Password must include at least one number';
    }
    if (!RegExp(r'[^\w]').hasMatch(value)) {
      setState(() {
        isPasswordValid = false;
      });
      return 'Password must include at least one special character';
    }

    setState(() {
      isPasswordValid = true;
    });

    return "valid";
  }

  String? validateConfirmPassword(String value) {
    if (value != _passwordController.text) {
      setState(() {
        isPasswordConfirmed = false;
      });
      return 'Passwords do not match';
    }
    setState(() {
      isPasswordConfirmed = true;
    });
    return 'confirmed';
  }

  bool _isAtLeastYearsOld(
    String dateString, {
    int minAge = 18,
    DateTime? referenceDate,
  }) {
    if (dateString != "") {
      try {
        final format = DateFormat('d/M/yyyy');
        final birthDate = format.parse(dateString);
        final today = referenceDate ?? DateTime.now();
        final age =
            today.year -
            birthDate.year -
            (today.month < birthDate.month ||
                    (today.month == birthDate.month &&
                        today.day < birthDate.day)
                ? 1
                : 0);
        return age >= minAge;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  bool _allFilledOut() {
    if (user == null) {
      if (_firstNameController.text.isNotEmpty &&
          validateName(_firstNameController.text) &&
          _lastNameController.text.isNotEmpty &&
          validateName(_lastNameController.text) &&
          _emailController.text.isNotEmpty &&
          isValid &&
          _phoneNumberController.text.isNotEmpty &&
          validatePhoneNumber(_phoneNumberController.text) &&
          _birthDayController.text.isNotEmpty &&
          _isAtLeastYearsOld(_birthDayController.text) &&
          _languageController.text.isNotEmpty &&
          _experienceController.text.isNotEmpty &&
          validateExperience(_experienceController.text) &&
          _roleController.text.isNotEmpty &&
          _fathersNameController.text.isNotEmpty &&
          validateName(_fathersNameController.text) &&
          _genderController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          isPasswordValid &&
          _confirmPasswordController.text.isNotEmpty &&
          isPasswordConfirmed &&
          isChecked &&
          ((_roleController.text == 'Guide') ||
              (_roleController.text != 'Guide' &&
                  _vehicleTypeController.text.isNotEmpty))) {
        return true;
      }
      return false;
    } else {
      if (_firstNameController.text.isNotEmpty &&
          validateName(_firstNameController.text) &&
          _lastNameController.text.isNotEmpty &&
          validateName(_lastNameController.text) &&
          _phoneNumberController.text.isNotEmpty &&
          validatePhoneNumber(_phoneNumberController.text) &&
          _birthDayController.text.isNotEmpty &&
          _isAtLeastYearsOld(_birthDayController.text) &&
          _languageController.text.isNotEmpty &&
          _experienceController.text.isNotEmpty &&
          validateExperience(_experienceController.text) &&
          _roleController.text.isNotEmpty &&
          _fathersNameController.text.isNotEmpty &&
          validateName(_fathersNameController.text) &&
          _genderController.text.isNotEmpty &&
          isPasswordValid &&
          isPasswordConfirmed &&
          isChecked &&
          ((_roleController.text == 'Guide') ||
              (_roleController.text != 'Guide' &&
                  _vehicleTypeController.text.isNotEmpty))) {
        return true;
      }
      return false;
    }
  }

  void _isEmpty(TextEditingController controller, String fieldName) {
    setState(() {
      if (fieldName == 'firstName') {
        isFirstNameEmpty =
            controller.text.isEmpty || !validateName(controller.text);
      } else if (fieldName == 'lastName') {
        isLastNameEmpty =
            controller.text.isEmpty || !validateName(controller.text);
      } else if (fieldName == 'email') {
        isEmailEmpty = controller.text.isEmpty;
        isValid = validateEmail(controller.text);
      } else if (fieldName == 'phoneNumber') {
        isPhoneNumberEmpty = controller.text.isEmpty;
        isPhoneNumberValid = validatePhoneNumber(controller.text);
      } else if (fieldName == 'language') {
        isLanguageEmpty = controller.text.isEmpty;
      } else if (fieldName == 'birthDay') {
        isBirthDayEmpty = controller.text.isEmpty;
      } else if (fieldName == 'experience') {
        isExperienceEmpty =
            controller.text.isEmpty || !validateExperience(controller.text);
      } else if (fieldName == 'vehicleType') {
        isVehicleTypeEmpty = controller.text.isEmpty;
      } else if (fieldName == 'role') {
        isRoleEmpty = controller.text.isEmpty;
      } else if (fieldName == 'fathersName') {
        isFathersNameEmpty =
            controller.text.isEmpty || !validateName(controller.text);
      } else if (fieldName == 'gender') {
        isGenderEmpty = controller.text.isEmpty;
      } else if (fieldName == 'confirmPassword') {
        isConfirmPasswordEmpty = controller.text.isEmpty;
      }
    });
  }

  Future<void> _submitForm() async {
    await signUp(
      emailController: _emailController,
      passwordController: _passwordController,
      firstNameController: _firstNameController,
      lastNameController: _lastNameController,
      fathersNameController: _fathersNameController,
      phoneNumberController: _phoneNumberController,
      languageController: _languageController,
      birthDayController: _birthDayController,
      experienceController: _experienceController,
      vehicleTypeController: _vehicleTypeController,
      roleController: _roleController,
      genderController: _genderController,
      context: context,
    );
    _clearFormData();
  }

  void _checkFields() {
    if (_firstNameController.text.isEmpty) {
      _firstNameFocusNode.requestFocus();
      return;
    } else if (_lastNameController.text.isEmpty) {
      _lastNameFocusNode.requestFocus();
      return;
    } else if (_fathersNameController.text.isEmpty) {
      _fathersNameFocusNode.requestFocus();
      return;
    } else if (_birthDayController.text.isEmpty) {
      _birthDayFocusNode.requestFocus();
      return;
    } else if (_genderController.text.isEmpty) {
      _genderFocusNode.requestFocus();
      return;
    } else if (_emailController.text.isEmpty || !isValid) {
      _emailFocusNode.requestFocus();
      return;
    } else if (_passwordController.text.isEmpty || !isPasswordValid) {
      _passwordFocusNode.requestFocus();
      return;
    } else if (_confirmPasswordController.text.isEmpty ||
        !isPasswordConfirmed) {
      _confirmPasswordFocusNode.requestFocus();
      return;
    } else if (_phoneNumberController.text.isEmpty || !isPhoneNumberValid) {
      _phoneNumberFocusNode.requestFocus();
      return;
    } else if (_roleController.text.isEmpty) {
      _roleFocusNode.requestFocus();
      return;
    } else if (_experienceController.text.isEmpty) {
      _experienceFocusNode.requestFocus();
      return;
    } else if (_languageController.text.isEmpty) {
      _languageFocusNode.requestFocus();
      return;
    } else if (_roleController.text != 'Guide' &&
        _vehicleTypeController.text.isEmpty) {
      _vehicleTypeFocusNode.requestFocus();
      return;
    } else if (!isChecked) {
      return;
    }
  }

  @override
  void initState() {
    super.initState();

    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _phoneNumberFocusNode = FocusNode();
    _languageFocusNode = FocusNode();
    _birthDayFocusNode = FocusNode();
    _experienceFocusNode = FocusNode();
    _vehicleTypeFocusNode = FocusNode();
    _roleFocusNode = FocusNode();
    _fathersNameFocusNode = FocusNode();
    _genderFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();

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

    _firstNameFocusNode.addListener(() {
      if (!_firstNameFocusNode.hasFocus) {
        _isEmpty(_firstNameController, 'firstName');
      }
    });
    _lastNameFocusNode.addListener(() {
      if (!_lastNameFocusNode.hasFocus) {
        _isEmpty(_lastNameController, 'lastName');
      }
    });
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _isEmpty(_emailController, 'email');
      }
    });
    _phoneNumberFocusNode.addListener(() {
      if (!_phoneNumberFocusNode.hasFocus) {
        _isEmpty(_phoneNumberController, 'phoneNumber');
      }
    });
    _languageFocusNode.addListener(() {
      if (!_languageFocusNode.hasFocus) {
        _isEmpty(_languageController, 'language');
      } else {
        _openLanguagePicker();
      }
    });
    _birthDayFocusNode.addListener(() {
      if (!_birthDayFocusNode.hasFocus) {
        _isEmpty(_birthDayController, 'birthDay');
      } else {
        _openDatePicker();
      }
    });
    _experienceFocusNode.addListener(() {
      if (!_experienceFocusNode.hasFocus) {
        _isEmpty(_experienceController, 'experience');
      }
    });
    _vehicleTypeFocusNode.addListener(() {
      if (!_vehicleTypeFocusNode.hasFocus) {
        _isEmpty(_vehicleTypeController, 'vehicleType');
      } else {
        _openVehicleTypePicker();
      }
    });
    _roleFocusNode.addListener(() {
      if (!_roleFocusNode.hasFocus) {
        _isEmpty(_roleController, 'role');
      } else {
        _openRolePicker();
      }
    });
    _fathersNameFocusNode.addListener(() {
      if (!_fathersNameFocusNode.hasFocus) {
        _isEmpty(_fathersNameController, 'fathersName');
      }
    });
    _genderFocusNode.addListener(() async {
      if (!_genderFocusNode.hasFocus) {
        _isEmpty(_genderController, 'gender');
      } else {
        _openGenderPicker();
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _isEmpty(_passwordController, 'password');
        setState(() {
          passwordObscure = true;
        });
      }
    });
    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus) {
        _isEmpty(_confirmPasswordController, 'confirmPassword');
        setState(() {
          confirmPasswordObscure = true;
        });
      }
    });

    _firstNameController.addListener(() {
      setState(() {});
      _isEmpty(_firstNameController, 'firstName');
      _saveFormData();
    });
    _lastNameController.addListener(() {
      setState(() {});
      _isEmpty(_lastNameController, 'lastName');
      _saveFormData();
    });
    _fathersNameController.addListener(() {
      setState(() {});
      _isEmpty(_fathersNameController, 'fathersName');
      _saveFormData();
    });
    _birthDayController.addListener(() {
      setState(() {});
      _isEmpty(_birthDayController, 'birthDay');
      _saveFormData();
    });
    _genderController.addListener(() {
      setState(() {});
      _isEmpty(_genderController, 'gender');
      _saveFormData();
    });
    _emailController.addListener(() {
      setState(() {});
      _saveFormData();
    });
    _passwordController.addListener(() {
      setState(() {});
      _saveFormData();
    });
    _confirmPasswordController.addListener(() {
      setState(() {});
      _saveFormData();
    });
    _phoneNumberController.addListener(() {
      setState(() {
        characterCount = _phoneNumberController.text.length;
        _isEmpty(_phoneNumberController, 'phoneNumber');
      });
      _saveFormData();
    });
    _roleController.addListener(() {
      setState(() {});
      _isEmpty(_roleController, 'role');
      _saveFormData();
    });
    _experienceController.addListener(() {
      setState(() {});
      _isEmpty(_experienceController, 'experience');
      _saveFormData();
    });
    _languageController.addListener(() {
      setState(() {});
      _isEmpty(_languageController, 'language');
      _saveFormData();
    });
    _vehicleTypeController.addListener(() {
      setState(() {});
      _isEmpty(_vehicleTypeController, 'vehicleType');
      _saveFormData();
    });

    _loadFormData();
  }

  Future<void> _openDatePicker() async {
    await Future.delayed(Duration(milliseconds: 100));
    if (mounted) {
      await selectDate(context: context, controller: _birthDayController);

      _isEmpty(_birthDayController, 'birthDay');

      _isAtLeastYearsOld(_birthDayController.text);
    }
    _genderFocusNode.requestFocus();
  }

  Future<void> _openGenderPicker() async {
    await Future.delayed(Duration(milliseconds: 100));
    if (mounted) {
      await showGenderPicker(context, _genderController);
      _isEmpty(_genderController, 'gender');
    }
    if (user == null) {
      _emailFocusNode.requestFocus();
    } else {
      _phoneNumberFocusNode.requestFocus();
    }
  }

  Future<void> _openRolePicker() async {
    await Future.delayed(Duration(milliseconds: 100));
    if (mounted) {
      await showRolePicker(context, _roleController);
      _isEmpty(_roleController, 'role');
    }
    _experienceFocusNode.requestFocus();
  }

  Future<void> _openLanguagePicker() async {
    await Future.delayed(Duration(milliseconds: 100));
    if (mounted) {
      await showLanguangePicker(context, selectedLanguages);
      _languageController.text = selectedLanguages.join(', ');
      _isEmpty(_languageController, 'language');
    }
    if (_roleController.text == 'Guide') {
      _languageFocusNode.unfocus();
    } else {
      _vehicleTypeFocusNode.requestFocus();
    }
  }

  Future<void> _openVehicleTypePicker() async {
    await Future.delayed(Duration(milliseconds: 100));
    if (mounted) {
      await showVehicleTypePicker(
        context,
        selectedVehicleType,
        singleSelection: false,
      );
      _vehicleTypeController.text = selectedVehicleType.join(', ');
      _isEmpty(_vehicleTypeController, 'vehicleType');
    }
    setState(() {
      _vehicleTypeFocusNode.unfocus();
    });
  }

  Future<void> _saveFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', _firstNameController.text);
    await prefs.setString('lastName', _lastNameController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('phoneNumber', _phoneNumberController.text);
    await prefs.setString('language', _languageController.text);
    await prefs.setString('birthDay', _birthDayController.text);
    await prefs.setString('experience', _experienceController.text);
    await prefs.setString('vehicleType', _vehicleTypeController.text);
    await prefs.setString('role', _roleController.text);
    await prefs.setString('fathersName', _fathersNameController.text);
    await prefs.setString('gender', _genderController.text);
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('confirmPassword', _confirmPasswordController.text);
  }

  Future<void> _clearFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _loadFormData() async {
    final user = this.user;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _firstNameController.text = data['First Name'] ?? '';
        _lastNameController.text = data['Last Name'] ?? '';
        _emailController.text = data['E-mail'] ?? '';
        _phoneNumberController.text = data['Phone number'] ?? '';
        _languageController.text = data['Language spoken'] ?? '';
        _birthDayController.text = data['Day of Birth'] ?? '';
        final experienceString = data['Experience'] ?? '';
        final experienceMatch = RegExp(r'(\d+)').firstMatch(experienceString);
        _experienceController.text =
            experienceMatch != null ? experienceMatch.group(1)! : '';
        _vehicleTypeController.text = data['Vehicle Type'] ?? '';
        selectedVehicleType =
            _vehicleTypeController.text.isNotEmpty
                ? _vehicleTypeController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toSet()
                : {};
        _roleController.text = data['Role'] ?? '';
        _fathersNameController.text = data['Father\'s Name'] ?? '';
        _genderController.text = data['Gender'] ?? '';
      }
    }
    final prefs = await SharedPreferences.getInstance();
    _firstNameController.text =
        prefs.getString('firstName') ?? _firstNameController.text;
    _lastNameController.text =
        prefs.getString('lastName') ?? _lastNameController.text;
    _emailController.text = prefs.getString('email') ?? _emailController.text;
    _phoneNumberController.text =
        prefs.getString('phoneNumber') ?? _phoneNumberController.text;
    _languageController.text =
        prefs.getString('language') ?? _languageController.text;
    _birthDayController.text =
        prefs.getString('birthDay') ?? _birthDayController.text;
    _experienceController.text =
        prefs.getString('experience') ?? _experienceController.text;
    _vehicleTypeController.text =
        prefs.getString('vehicleType') ?? _vehicleTypeController.text;
    _roleController.text = prefs.getString('role') ?? _roleController.text;
    _fathersNameController.text =
        prefs.getString('fathersName') ?? _fathersNameController.text;
    _genderController.text =
        prefs.getString('gender') ?? _genderController.text;
    _passwordController.text = prefs.getString('password') ?? '';
    _confirmPasswordController.text = prefs.getString('confirmPassword') ?? '';
  }

  @override
  void dispose() {
    _scrollController.dispose();

    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _languageFocusNode.dispose();
    _birthDayFocusNode.dispose();
    _experienceFocusNode.dispose();
    _vehicleTypeFocusNode.dispose();
    _roleFocusNode.dispose();
    _fathersNameFocusNode.dispose();
    _genderFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _languageController.dispose();
    _birthDayController.dispose();
    _experienceController.dispose();
    _vehicleTypeController.dispose();
    _roleController.dispose();
    _fathersNameController.dispose();
    _genderController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

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
            'Ready to become a driver or a tour guide?',
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
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to become a driver or a tour guide?',
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
                  'Before we get you started as our partner, we just need a few details from you. Fill out the quick application below, and we\' get the ball rolling!',
                ),
                SizedBox(height: height * 0.015),
                //FIRSTNAME
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isFirstNameEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _firstNameFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: _firstNameFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          _firstNameFocusNode.requestFocus();
                        });
                      },
                      onChanged: (value) {
                        _isEmpty(_firstNameController, 'firstName');
                      },
                      onTapOutside: (_) {
                        setState(() {
                          _firstNameFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _firstNameFocusNode,
                      onEditingComplete: () {
                        _firstNameFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_lastNameFocusNode);
                      },
                      controller: _firstNameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Zа-яА-Я\s]"),
                        ),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final text = newValue.text;
                          if (text.isEmpty) return newValue;
                          final capitalized = text.replaceAllMapped(
                            RegExp(r'(^\w{1}|\s\w{1})'),
                            (match) => match.group(0)!.toUpperCase(),
                          );
                          return TextEditingValue(
                            text: capitalized,
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      decoration: InputDecoration(
                        suffixIcon:
                            _firstNameFocusNode.hasFocus
                                ? _firstNameController.text.isEmpty
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
                                        _firstNameController.text = '';
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
                        labelText: 'First name (as in passport)',
                        hintText: 'eg. Jane',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isFirstNameEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _firstNameFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isFirstNameEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      _firstNameController.text.isEmpty
                          ? "Required"
                          : "Only letters allowed",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //LASTNAME
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isLastNameEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _lastNameFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: _lastNameFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          _lastNameFocusNode.requestFocus();
                        });
                      },
                      onChanged: (value) {
                        _isEmpty(_lastNameController, 'lastName');
                      },
                      onTapOutside: (_) {
                        setState(() {
                          _lastNameFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _lastNameFocusNode,
                      onEditingComplete: () {
                        _lastNameFocusNode.unfocus();
                        FocusScope.of(
                          context,
                        ).requestFocus(_fathersNameFocusNode);
                      },
                      controller: _lastNameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Zа-яА-Я\s]"),
                        ),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final text = newValue.text;
                          if (text.isEmpty) return newValue;
                          final capitalized = text.replaceAllMapped(
                            RegExp(r'(^\w{1}|\s\w{1})'),
                            (match) => match.group(0)!.toUpperCase(),
                          );
                          return TextEditingValue(
                            text: capitalized,
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      decoration: InputDecoration(
                        suffixIcon:
                            _lastNameFocusNode.hasFocus
                                ? _lastNameController.text.isEmpty
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
                                        _lastNameController.text = '';
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
                        labelText: 'Last name (as in passport)',
                        hintText: 'eg. Doe',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isLastNameEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _lastNameFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isLastNameEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      _lastNameController.text.isEmpty
                          ? "Required"
                          : "Only letters allowed",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //FATHER'S NAME
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isFathersNameEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _fathersNameFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: _fathersNameFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          _fathersNameFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_fathersNameController, 'fathersName');
                        setState(() {
                          _fathersNameFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _fathersNameFocusNode,
                      onEditingComplete: () {
                        _fathersNameFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_birthDayFocusNode);
                      },
                      controller: _fathersNameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Zа-яА-Я\s]"),
                        ),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final text = newValue.text;
                          if (text.isEmpty) return newValue;
                          final capitalized = text.replaceAllMapped(
                            RegExp(r'(^\w{1}|\s\w{1})'),
                            (match) => match.group(0)!.toUpperCase(),
                          );
                          return TextEditingValue(
                            text: capitalized,
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      decoration: InputDecoration(
                        suffixIcon:
                            _fathersNameFocusNode.hasFocus
                                ? _fathersNameController.text.isEmpty
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
                                        _fathersNameController.text = '';
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
                        labelText: 'Father\'s name (as in passport)',
                        hintText: 'eg. Russell',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isFathersNameEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _fathersNameFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isFathersNameEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      _fathersNameController.text.isEmpty
                          ? "Required"
                          : "Only letters allowed",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //DATE OF BIRTH
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isBirthDayEmpty ||
                                  !_isAtLeastYearsOld(_birthDayController.text)
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _birthDayFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: _birthDayFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () async {
                        setState(() {
                          _birthDayFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_birthDayController, 'birthDay');
                        setState(() {
                          _birthDayFocusNode.unfocus();
                        });
                      },
                      readOnly: true,
                      showCursor: false,
                      focusNode: _birthDayFocusNode,
                      onEditingComplete: () {
                        _birthDayFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_genderFocusNode);
                      },
                      controller: _birthDayController,
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
                        labelText: 'Date of birth',
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isBirthDayEmpty ||
                                      !_isAtLeastYearsOld(
                                        _birthDayController.text,
                                      )
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _birthDayFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isBirthDayEmpty ||
                    !_isAtLeastYearsOld(_birthDayController.text))
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      isBirthDayEmpty
                          ? "Required"
                          : "You must be at least 18 years old to apply.",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //GENDER
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isGenderEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _genderFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: _genderFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () async {
                        setState(() {
                          _genderFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_genderController, 'gender');
                        setState(() {
                          _genderFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      readOnly: true,
                      focusNode: _genderFocusNode,
                      onEditingComplete: () {
                        _genderFocusNode.unfocus();
                        if (user == null) {
                          FocusScope.of(context).requestFocus(_emailFocusNode);
                        } else {
                          FocusScope.of(
                            context,
                          ).requestFocus(_phoneNumberFocusNode);
                        }
                      },
                      controller: _genderController,
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
                        labelText: 'Choose your gender',
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isGenderEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _genderFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isGenderEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //EMAIL
                user == null
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: width,
                          height: height * 0.065,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  isEmailEmpty || !isValid
                                      ? const Color.fromARGB(255, 244, 92, 54)
                                      : _emailFocusNode.hasFocus
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(width * 0.019),
                          ),
                          padding: EdgeInsets.only(
                            bottom:
                                _emailFocusNode.hasFocus ? 0 : width * 0.025,
                            left: width * 0.025,
                            top: width * 0.025,
                            right: width * 0.025,
                          ),
                          child: Center(
                            child: TextField(
                              onChanged: _validateEmail,
                              onTap: () {
                                setState(() {
                                  _emailFocusNode.requestFocus();
                                });
                              },
                              onTapOutside: (_) {
                                _isEmpty(_emailController, 'email');
                                setState(() {
                                  _emailFocusNode.unfocus();
                                });
                              },
                              showCursor: false,
                              focusNode: _emailFocusNode,
                              onEditingComplete: () {
                                _emailFocusNode.unfocus();
                                FocusScope.of(
                                  context,
                                ).requestFocus(_passwordFocusNode);
                              },
                              controller: _emailController,
                              decoration: InputDecoration(
                                suffixIcon:
                                    _emailFocusNode.hasFocus
                                        ? (_emailController.text.isEmpty
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
                                                _emailController.text = '';
                                              },
                                              icon: Icon(Icons.cancel),
                                              padding: EdgeInsets.zero,
                                              iconSize: width * 0.076,
                                            ))
                                        : null,
                                errorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                  top: width * 0.05,
                                ),
                                isDense: true,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                labelText: 'Email',
                                hintText: 'Email',
                                hintStyle: TextStyle(
                                  fontSize: width * 0.038,
                                  color: Colors.grey.shade500.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                                labelStyle: TextStyle(
                                  fontSize: width * 0.038,
                                  color:
                                      isEmailEmpty || !isValid
                                          ? const Color.fromARGB(
                                            255,
                                            244,
                                            92,
                                            54,
                                          )
                                          : _emailFocusNode.hasFocus
                                          ? Colors.blue
                                          : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isEmailEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.027,
                              top: width * 0.007,
                            ),
                            child: Text(
                              "Required",
                              style: TextStyle(
                                fontSize: width * 0.03,
                                color: const Color.fromARGB(255, 244, 92, 54),
                              ),
                            ),
                          ),
                        if (!isValid && !isEmailEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.027,
                              top: width * 0.007,
                            ),
                            child: Text(
                              "Invalid email adress",

                              style: TextStyle(
                                fontSize: width * 0.03,
                                color: const Color.fromARGB(255, 244, 92, 54),
                              ),
                            ),
                          ),
                        SizedBox(height: height * 0.015),
                        //PASSWORD
                        Container(
                          width: width,
                          height: height * 0.065,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  !isPasswordValid
                                      ? const Color.fromARGB(255, 244, 92, 54)
                                      : _passwordFocusNode.hasFocus
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(width * 0.019),
                          ),
                          padding: EdgeInsets.only(
                            bottom:
                                _passwordFocusNode.hasFocus ? 0 : width * 0.025,
                            left: width * 0.025,
                            top: width * 0.025,
                            right: width * 0.025,
                          ),
                          child: Center(
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  passwordValidationString =
                                      validatePassword(value)!;
                                });
                              },
                              onTap: () {
                                setState(() {
                                  _passwordFocusNode.requestFocus();
                                });
                              },
                              onTapOutside: (_) {
                                setState(() {
                                  _passwordFocusNode.unfocus();
                                  passwordObscure = true;
                                });
                              },
                              showCursor: false,
                              focusNode: _passwordFocusNode,
                              onEditingComplete: () {
                                _passwordFocusNode.unfocus();
                                FocusScope.of(
                                  context,
                                ).requestFocus(_confirmPasswordFocusNode);
                              },
                              obscureText: passwordObscure,
                              controller: _passwordController,
                              decoration: InputDecoration(
                                suffixIcon:
                                    _passwordFocusNode.hasFocus
                                        ? (_passwordController.text.isEmpty
                                            ? Icon(
                                              Icons.remove_red_eye_outlined,
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
                                                setState(() {
                                                  passwordObscure =
                                                      !passwordObscure;
                                                });
                                              },
                                              icon: Icon(
                                                Icons.remove_red_eye_outlined,
                                              ),
                                              padding: EdgeInsets.zero,
                                              iconSize: width * 0.076,
                                            ))
                                        : null,
                                errorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                  top: width * 0.05,
                                ),
                                isDense: true,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  fontSize: width * 0.038,
                                  color:
                                      !isPasswordValid
                                          ? const Color.fromARGB(
                                            255,
                                            244,
                                            92,
                                            54,
                                          )
                                          : _passwordFocusNode.hasFocus
                                          ? Colors.blue
                                          : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!isPasswordValid)
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.027,
                              top: width * 0.007,
                            ),
                            child: Text(
                              passwordValidationString,
                              style: TextStyle(
                                fontSize: width * 0.03,
                                color: const Color.fromARGB(255, 244, 92, 54),
                              ),
                            ),
                          ),

                        SizedBox(height: height * 0.015),
                        //CONFIRM PASSWORD
                        Container(
                          width: width,
                          height: height * 0.065,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  isConfirmPasswordEmpty || !isPasswordConfirmed
                                      ? const Color.fromARGB(255, 244, 92, 54)
                                      : _confirmPasswordFocusNode.hasFocus
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(width * 0.019),
                          ),
                          padding: EdgeInsets.only(
                            bottom:
                                _confirmPasswordFocusNode.hasFocus
                                    ? 0
                                    : width * 0.025,
                            left: width * 0.025,
                            top: width * 0.025,
                            right: width * 0.025,
                          ),
                          child: Center(
                            child: TextField(
                              onChanged: (value) {
                                validateConfirmPassword(value);
                              },
                              onTap: () {
                                setState(() {
                                  _confirmPasswordFocusNode.requestFocus();
                                });
                              },
                              onTapOutside: (_) {
                                _isEmpty(
                                  _confirmPasswordController,
                                  'confirmPassword',
                                );
                                setState(() {
                                  _confirmPasswordFocusNode.unfocus();
                                });
                                if (confirmPasswordObscure == false ||
                                    !_confirmPasswordFocusNode.hasFocus) {
                                  setState(() {
                                    confirmPasswordObscure = true;
                                  });
                                }
                              },
                              onSubmitted: (_) {
                                setState(() {
                                  confirmPasswordObscure = true;
                                });
                              },
                              obscureText: confirmPasswordObscure,
                              showCursor: false,
                              focusNode: _confirmPasswordFocusNode,
                              onEditingComplete: () {
                                _confirmPasswordFocusNode.unfocus();
                                FocusScope.of(
                                  context,
                                ).requestFocus(_phoneNumberFocusNode);
                              },
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                suffixIcon:
                                    _confirmPasswordFocusNode.hasFocus
                                        ? _confirmPasswordController
                                                .text
                                                .isEmpty
                                            ? Icon(
                                              Icons.remove_red_eye_outlined,
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
                                                setState(() {
                                                  confirmPasswordObscure =
                                                      !confirmPasswordObscure;
                                                });
                                              },
                                              icon: Icon(
                                                Icons.remove_red_eye_outlined,
                                              ),
                                              padding: EdgeInsets.zero,
                                              iconSize: width * 0.076,
                                            )
                                        : null,
                                errorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                  top: width * 0.05,
                                ),
                                isDense: true,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                labelText: 'Confirm password',
                                labelStyle: TextStyle(
                                  fontSize: width * 0.038,
                                  color:
                                      isConfirmPasswordEmpty ||
                                              !isPasswordConfirmed
                                          ? const Color.fromARGB(
                                            255,
                                            244,
                                            92,
                                            54,
                                          )
                                          : _confirmPasswordFocusNode.hasFocus
                                          ? Colors.blue
                                          : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isConfirmPasswordEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.027,
                              top: width * 0.007,
                            ),
                            child: Text(
                              "Required",
                              style: TextStyle(
                                fontSize: width * 0.03,
                                color: const Color.fromARGB(255, 244, 92, 54),
                              ),
                            ),
                          ),

                        if (!isPasswordConfirmed)
                          Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.027,
                              top: width * 0.007,
                            ),
                            child: Text(
                              'Passwords do not match',
                              style: TextStyle(
                                fontSize: width * 0.03,
                                color: const Color.fromARGB(255, 244, 92, 54),
                              ),
                            ),
                          ),
                        SizedBox(height: height * 0.015),
                      ],
                    )
                    : SizedBox.shrink(),
                //PHONE NUMBER
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isPhoneNumberEmpty || !isPhoneNumberValid
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _phoneNumberFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: _phoneNumberFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onChanged: (_) {
                        if (!isPhoneNumberEmpty) {
                          isPhoneNumberValid = characterCount >= 13;
                        }
                      },
                      onTap: () {
                        setState(() {
                          _phoneNumberFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_phoneNumberController, 'phoneNumber');
                        setState(() {
                          _phoneNumberFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      keyboardType: TextInputType.phone,
                      focusNode: _phoneNumberFocusNode,
                      onEditingComplete: () {
                        _phoneNumberFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_roleFocusNode);
                      },
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        suffixIcon:
                            _phoneNumberFocusNode.hasFocus
                                ? _phoneNumberController.text.isEmpty
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
                                        _phoneNumberController.text = '';
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
                        labelText: 'Phone number (international format)',
                        hintText: 'eg. +358411235522',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isPhoneNumberEmpty || !isPhoneNumberValid
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _phoneNumberFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isPhoneNumberEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                if (!isPhoneNumberValid && !isPhoneNumberEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Invalid Phone number format",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),

                //ROLE
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isRoleEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _roleFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: _roleFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () async {
                        setState(() {
                          _roleFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_roleController, 'role');
                        setState(() {
                          _roleFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      readOnly: true,
                      focusNode: _roleFocusNode,
                      onEditingComplete: () {
                        _roleFocusNode.unfocus();
                        FocusScope.of(
                          context,
                        ).requestFocus(_experienceFocusNode);
                      },
                      controller: _roleController,
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
                        labelText: 'Choose your role',
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isRoleEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _roleFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isRoleEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //EXPERIENCE
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isExperienceEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _experienceFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom: _experienceFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          _experienceFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_experienceController, 'experience');
                        setState(() {
                          _experienceFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _experienceFocusNode,
                      onEditingComplete: () {
                        _experienceFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_languageFocusNode);
                      },
                      keyboardType: TextInputType.number,
                      controller: _experienceController,
                      decoration: InputDecoration(
                        suffixIcon:
                            _experienceFocusNode.hasFocus
                                ? _experienceController.text.isEmpty
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
                                        _experienceController.text = '';
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
                        labelText: 'Experience',
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isExperienceEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _experienceFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isExperienceEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      _experienceController.text.isEmpty
                          ? "Required"
                          : "Must be a positive number",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                //LANGUAGE
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isLanguageEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _languageFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        _languageFocusNode.hasFocus || !isLanguageEmpty
                            ? 0
                            : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onTap: () async {
                        setState(() {
                          _languageFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_languageController, 'language');
                        setState(() {
                          _languageFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      readOnly: true,
                      focusNode: _languageFocusNode,

                      onEditingComplete: () {
                        if (_roleController.text == 'Guide') {
                          FocusScope.of(context).unfocus();
                        } else {
                          _languageFocusNode.unfocus();
                          FocusScope.of(
                            context,
                          ).requestFocus(_vehicleTypeFocusNode);
                        }
                      },
                      controller: _languageController,
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
                        labelText: 'Languages spoken',
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isLanguageEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _languageFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isLanguageEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      "Required",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(
                  height:
                      _roleController.text == 'Driver' ||
                              _roleController.text == 'Driver Cum Guide'
                          ? height * 0.015
                          : height * 0.045,
                ),
                //VEHICLE TYPE
                _roleController.text == 'Driver' ||
                        _roleController.text == 'Driver Cum Guide'
                    ? SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: width,
                            height: height * 0.065,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isVehicleTypeEmpty
                                        ? const Color.fromARGB(255, 244, 92, 54)
                                        : _vehicleTypeFocusNode.hasFocus
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                              ),
                              borderRadius: BorderRadius.circular(
                                width * 0.019,
                              ),
                            ),
                            padding: EdgeInsets.only(
                              bottom:
                                  _vehicleTypeFocusNode.hasFocus
                                      ? 0
                                      : width * 0.025,
                              left: width * 0.025,
                              top: width * 0.025,
                              right: width * 0.025,
                            ),
                            child: Center(
                              child: TextField(
                                onTap: () async {
                                  setState(() {
                                    _vehicleTypeFocusNode.requestFocus();
                                  });
                                },
                                onTapOutside: (_) {
                                  _isEmpty(
                                    _vehicleTypeController,
                                    'vehicleType',
                                  );
                                  setState(() {
                                    _vehicleTypeFocusNode.unfocus();
                                  });
                                },
                                readOnly: true,
                                focusNode: _vehicleTypeFocusNode,
                                onEditingComplete: () {
                                  _vehicleTypeFocusNode.unfocus();
                                },
                                controller: _vehicleTypeController,
                                decoration: InputDecoration(
                                  suffixIcon: Icon(
                                    Icons.chevron_right_rounded,
                                    size: width * 0.085,
                                  ),
                                  errorBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.only(
                                    top: width * 0.05,
                                  ),
                                  isDense: true,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto,
                                  labelText: 'Vehicle Type',
                                  labelStyle: TextStyle(
                                    fontSize: width * 0.038,
                                    color:
                                        isVehicleTypeEmpty
                                            ? const Color.fromARGB(
                                              255,
                                              244,
                                              92,
                                              54,
                                            )
                                            : _vehicleTypeFocusNode.hasFocus
                                            ? Colors.blue
                                            : Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isVehicleTypeEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                left: width * 0.027,
                                top: width * 0.007,
                              ),
                              child: Text(
                                "Required",
                                style: TextStyle(
                                  fontSize: width * 0.03,
                                  color: const Color.fromARGB(255, 244, 92, 54),
                                ),
                              ),
                            ),
                          SizedBox(height: height * 0.045),
                        ],
                      ),
                    )
                    : SizedBox.shrink(),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: width * 0.005,
                  children: [
                    Transform.scale(
                      scale: width * 0.0043,
                      child: Checkbox(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: isChecked,
                        side: BorderSide(
                          color: const Color.fromARGB(255, 33, 152, 243),
                          width: width * 0.005,
                        ),
                        activeColor: const Color.fromARGB(255, 33, 152, 243),
                        onChanged: (_) {
                          setState(() {
                            isChecked = !isChecked;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text:
                              'I have read and understand that my personal data will be processed in accordance with ',
                          children: [
                            TextSpan(
                              text: 'OnemoreTour Privacy Policy.',
                              style: TextStyle(color: Colors.blue),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.of(context).push(
                                        route(
                                          title: 'Privacy Policy',
                                          url:
                                              'https://onemoretour.com/privacy',
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.025),
                //MAIN BUTTON
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
                            isFromCertificateDetailsForm: false,
                            isFromCarDetailsSwitcher: false,
                            isFromProfilePage: false,
                            backgroundProcess: _submitForm,
                          ),
                        ),
                      );
                    } else {
                      _checkFields();
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
                        'Send application',
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
                SizedBox(height: height * 0.058),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
