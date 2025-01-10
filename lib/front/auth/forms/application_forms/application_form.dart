import 'package:driver_app/back/auth/firebase_auth.dart';
import 'package:driver_app/back/tools/date_picker.dart';
import 'package:driver_app/back/tools/gender_picker.dart';
import 'package:driver_app/back/tools/language_picker.dart';
import 'package:driver_app/back/tools/role_picker.dart';
import 'package:driver_app/back/tools/validate_email.dart';
import 'package:driver_app/back/tools/vehicle_type_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplicationForm extends StatefulWidget {
  const ApplicationForm({super.key});

  @override
  State<ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<ApplicationForm> {
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
    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
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

  bool _allFilledOut() {
    if (_firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneNumberController.text.isNotEmpty &&
        _birthDayController.text.isNotEmpty &&
        _languageController.text.isNotEmpty &&
        _experienceController.text.isNotEmpty &&
        _roleController.text.isNotEmpty &&
        _fathersNameController.text.isNotEmpty &&
        _genderController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _roleController.text == 'Guide' &&
        isValid &&
        isPasswordValid &&
        isPasswordConfirmed &&
        isChecked) {
      return true;
    } else if (_firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneNumberController.text.isNotEmpty &&
        _birthDayController.text.isNotEmpty &&
        _languageController.text.isNotEmpty &&
        _experienceController.text.isNotEmpty &&
        _roleController.text.isNotEmpty &&
        _fathersNameController.text.isNotEmpty &&
        _genderController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _roleController.text != 'Guide' &&
        _vehicleTypeController.text.isNotEmpty &&
        isValid &&
        isPasswordValid &&
        isPasswordConfirmed &&
        isChecked) {
      return true;
    }
    return false;
  }

  void _isEmpty(TextEditingController controller, String fieldName) {
    setState(() {
      if (controller.text.isEmpty) {
        if (fieldName == 'firstName') {
          isFirstNameEmpty = true;
        } else if (fieldName == 'lastName') {
          isLastNameEmpty = true;
        } else if (fieldName == 'email') {
          isEmailEmpty = true;
        } else if (fieldName == 'phoneNumber') {
          isPhoneNumberEmpty = true;
          isPhoneNumberValid = false;
        } else if (fieldName == 'language') {
          isLanguageEmpty = true;
        } else if (fieldName == 'birthDay') {
          isBirthDayEmpty = true;
        } else if (fieldName == 'experience') {
          isExperienceEmpty = true;
        } else if (fieldName == 'vehicleType') {
          isVehicleTypeEmpty = true;
        } else if (fieldName == 'role') {
          isRoleEmpty = true;
        } else if (fieldName == 'fathersName') {
          isFathersNameEmpty = true;
        } else if (fieldName == 'gender') {
          isGenderEmpty = true;
        } else if (fieldName == 'confirmPassword') {
          isConfirmPasswordEmpty = true;
        }
      } else {
        if (fieldName == 'firstName') {
          isFirstNameEmpty = false;
        } else if (fieldName == 'lastName') {
          isLastNameEmpty = false;
        } else if (fieldName == 'email') {
          isEmailEmpty = false;
        } else if (fieldName == 'phoneNumber') {
          isPhoneNumberEmpty = false;
        } else if (fieldName == 'language') {
          isLanguageEmpty = false;
        } else if (fieldName == 'birthDay') {
          isBirthDayEmpty = false;
        } else if (fieldName == 'experience') {
          isExperienceEmpty = false;
        } else if (fieldName == 'vehicleType') {
          isVehicleTypeEmpty = false;
        } else if (fieldName == 'role') {
          isRoleEmpty = false;
        } else if (fieldName == 'fathersName') {
          isFathersNameEmpty = false;
        } else if (fieldName == 'gender') {
          isGenderEmpty = false;
        } else if (fieldName == 'confirmPassword') {
          isConfirmPasswordEmpty = false;
        }
      }
    });
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
      }
    });
    _birthDayFocusNode.addListener(() {
      if (!_birthDayFocusNode.hasFocus) {
        _isEmpty(_birthDayController, 'birthDay');
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
      }
    });
    _roleFocusNode.addListener(() {
      if (!_roleFocusNode.hasFocus) {
        _isEmpty(_roleController, 'role');
      }
    });
    _fathersNameFocusNode.addListener(() {
      if (!_fathersNameFocusNode.hasFocus) {
        _isEmpty(_fathersNameController, 'fathersName');
      }
    });
    _genderFocusNode.addListener(() {
      if (!_genderFocusNode.hasFocus) {
        _isEmpty(_genderController, 'gender');
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
    });
    _lastNameController.addListener(() {
      setState(() {});
    });
    _fathersNameController.addListener(() {
      setState(() {});
    });
    _birthDayController.addListener(() {
      setState(() {});
    });
    _genderController.addListener(() {
      setState(() {});
    });
    _emailController.addListener(() {
      setState(() {});
    });
    _passwordController.addListener(() {
      setState(() {});
    });
    _confirmPasswordController.addListener(() {
      setState(() {});
    });
    _phoneNumberController.addListener(() {
      setState(() {
        characterCount = _phoneNumberController.text.length;
      });
    });
    _roleController.addListener(() {
      setState(() {});
    });
    _experienceController.addListener(() {
      setState(() {});
    });
    _languageController.addListener(() {
      setState(() {});
    });
    _vehicleTypeController.addListener(() {
      setState(() {});
    });
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
                      onTapOutside: (_) {
                        _isEmpty(_firstNameController, 'firstName');
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
                      "Required",
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
                      onTapOutside: (_) {
                        _isEmpty(_lastNameController, 'lastName');
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
                      "Required",
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
                      "Required",
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
                          isBirthDayEmpty
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
                        await selectDate(
                          context: context,
                          controller: _birthDayController,
                        );
                        _isEmpty(_birthDayController, 'birthDay');
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
                              isBirthDayEmpty
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
                if (isBirthDayEmpty)
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
                        await showGenderPicker(context, _genderController);
                        _isEmpty(_genderController, 'gender');
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
                        FocusScope.of(context).requestFocus(_emailFocusNode);
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
                    bottom: _emailFocusNode.hasFocus ? 0 : width * 0.025,
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
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
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
                        contentPadding: EdgeInsets.only(top: width * 0.05),
                        isDense: true,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        labelText: 'Email',
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isEmailEmpty || !isValid
                                  ? const Color.fromARGB(255, 244, 92, 54)
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
                    bottom: _passwordFocusNode.hasFocus ? 0 : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          passwordValidationString = validatePassword(value)!;
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
                                          passwordObscure = !passwordObscure;
                                        });
                                      },
                                      icon: Icon(Icons.remove_red_eye_outlined),
                                      padding: EdgeInsets.zero,
                                      iconSize: width * 0.076,
                                    ))
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
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              !isPasswordValid
                                  ? const Color.fromARGB(255, 244, 92, 54)
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
                        _confirmPasswordFocusNode.hasFocus ? 0 : width * 0.025,
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
                        _isEmpty(_confirmPasswordController, 'confirmPassword');
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
                                ? _confirmPasswordController.text.isEmpty
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
                                      icon: Icon(Icons.remove_red_eye_outlined),
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
                        labelText: 'Confirm password',
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isConfirmPasswordEmpty || !isPasswordConfirmed
                                  ? const Color.fromARGB(255, 244, 92, 54)
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
                        await showRolePicker(context, _roleController);
                        _isEmpty(_roleController, 'role');
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
                      "Required",
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

                        await showLanguangePicker(context, selectedLanguages);
                        _languageController.text = selectedLanguages.join(', ');
                        _isEmpty(_languageController, 'language');
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
                        _languageFocusNode.unfocus();
                        FocusScope.of(
                          context,
                        ).requestFocus(_vehicleTypeFocusNode);
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
                                  await showVehicleTypePicker(
                                    context,
                                    selectedVehicleType,
                                  );
                                  _vehicleTypeController
                                      .text = selectedVehicleType.join(', ');
                                  _isEmpty(
                                    _vehicleTypeController,
                                    'vehicleType',
                                  );
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
                          text: 'I have read and agree with the ',
                          children: [
                            TextSpan(
                              text: 'User Terms of Service',
                              style: TextStyle(color: Colors.blue),
                              recognizer: TapGestureRecognizer()..onTap = () {},
                            ),
                            TextSpan(
                              text:
                                  ', and I understand that my personal data will be processed in accordance with ',
                            ),
                            TextSpan(
                              text: 'OnemoreTour Privacy Policy',
                              style: TextStyle(color: Colors.blue),
                              recognizer: TapGestureRecognizer()..onTap = () {},
                            ),
                            TextSpan(text: '.'),
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
                    if (isTapped) return;
                    setState(() {
                      isTapped = true;
                    });
                    // if (_allFilledOut()) {
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
                    //   final success = await _apiService.postData(data);
                    //   if (success) {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       SnackBar(content: Text("Data posted successfully!")),
                    //     );
                    //   }
                    // }

                    setState(() {
                      isTapped = false;
                    });
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
