import 'package:country_picker/country_picker.dart';
import 'package:onemoretour/front/auth/auth_methods/auth_phone_alternative.dart';
// import 'package:onemoretour/back/tools/remove_emojis.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPhone extends StatefulWidget {
  const AuthPhone({super.key});

  @override
  State<AuthPhone> createState() => _AuthState();
}

class _AuthState extends State<AuthPhone> {
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  int _characterCount = 0;
  bool isCountryEmpty = false;
  bool isPhoneNumberEmpty = false;
  late FocusNode _countryCodeFocusNode;
  late FocusNode _phoneFocusNode;

  @override
  void initState() {
    super.initState();
    _countryCodeFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();

    _phoneNumberController.addListener(() {
      setState(() {
        _characterCount = _phoneNumberController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneNumberController.dispose();
    _countryCodeFocusNode.dispose();
    _phoneFocusNode.dispose();
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
        surfaceTintColor: Colors.transparent,
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
        backgroundColor: darkMode ? Colors.black : Colors.white,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(width * 0.02),
                  child: Text(
                    'Please enter your phone number',
                    style: GoogleFonts.daysOne(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.066,
                        color: darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.035),
                Padding(
                  padding: EdgeInsets.all(width * 0.02),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: width * 0.356,
                            height: height * 0.065,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isCountryEmpty
                                        ? const Color.fromARGB(255, 244, 92, 54)
                                        : _countryCodeFocusNode.hasFocus
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                              ),
                              borderRadius: BorderRadius.circular(
                                width * 0.019,
                              ),
                            ),
                            padding: EdgeInsets.only(
                              bottom:
                                  _countryCodeController.text.isNotEmpty
                                      ? 0
                                      : width * 0.025,
                              left: width * 0.025,
                              top: width * 0.038,
                              right: 0,
                            ),
                            child: Center(
                              child: TextField(
                                readOnly: true,
                                textInputAction: TextInputAction.next,
                                onTap: () {
                                  setState(() {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_countryCodeFocusNode);
                                  });
                                  Future.delayed(Duration(milliseconds: 200), () {
                                    if (context.mounted) {
                                      showCountryPicker(
                                        context: context,
                                        onSelect: (Country country) {
                                          setState(() {
                                            _countryCodeController.text =
                                                "${country.flagEmoji}+${country.phoneCode}";
                                            Future.delayed(
                                              const Duration(milliseconds: 100),
                                              () {},
                                            );
                                          });
                                        },
                                        onClosed: () {
                                          if (_countryCodeController
                                              .text
                                              .isEmpty) {
                                            isCountryEmpty = true;
                                          } else {
                                            isCountryEmpty = false;
                                            Future.delayed(
                                              Duration(milliseconds: 100),
                                              () {
                                                setState(() {
                                                  _phoneFocusNode
                                                      .requestFocus();
                                                });
                                              },
                                            );
                                          }
                                        },
                                        showPhoneCode: true,
                                        useSafeArea: true,
                                        moveAlongWithKeyboard: true,
                                        searchAutofocus: true,
                                        countryListTheme: CountryListThemeData(
                                          backgroundColor:
                                              darkMode
                                                  ? const Color.fromARGB(
                                                    255,
                                                    50,
                                                    50,
                                                    50,
                                                  )
                                                  : Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(
                                              width * 0.04,
                                            ),
                                            topRight: Radius.circular(
                                              width * 0.04,
                                            ),
                                          ),
                                          bottomSheetHeight: height * 0.856,
                                          padding: EdgeInsets.only(
                                            top: width * 0.045,
                                          ),
                                          inputDecoration: InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    width * 0.019,
                                                  ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    width * 0.019,
                                                  ),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color:
                                                  darkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                              size: width * 0.063,
                                            ),
                                            hintText: 'Search',
                                            hintStyle: TextStyle(
                                              color: const Color.fromARGB(
                                                255,
                                                141,
                                                141,
                                                141,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            filled: true,
                                            fillColor:
                                                darkMode
                                                    ? const Color.fromARGB(
                                                      255,
                                                      45,
                                                      45,
                                                      45,
                                                    )
                                                    : const Color.fromARGB(
                                                      255,
                                                      221,
                                                      221,
                                                      221,
                                                    ),
                                            constraints: BoxConstraints(
                                              minHeight: height * 0.041,
                                              maxHeight: height * 0.041,
                                            ),
                                            contentPadding: EdgeInsets.all(
                                              width * 0.02,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  });
                                },
                                controller: _countryCodeController,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  errorBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.only(
                                    top: width * 0.05,
                                  ),
                                  constraints: BoxConstraints(
                                    maxHeight: height * 0.065,
                                    minHeight: height * 0.065,
                                    maxWidth: width * 0.305,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.arrow_forward_ios,
                                    color:
                                        _countryCodeController.text.isEmpty
                                            ? Colors.grey.shade500
                                            : (darkMode
                                                ? Colors.white
                                                : Colors.black),
                                    size: width * 0.038,
                                  ),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto,
                                  labelText: 'Country',
                                  labelStyle: TextStyle(
                                    fontSize: width * 0.038,
                                    color:
                                        isCountryEmpty
                                            ? const Color.fromARGB(
                                              255,
                                              244,
                                              92,
                                              54,
                                            )
                                            : _countryCodeFocusNode.hasFocus
                                            ? Colors.blue
                                            : Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isCountryEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                left: width * 0.04,
                                top: width * 0.007,
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: width * 0.03,
                                  color: const Color.fromARGB(255, 244, 92, 54),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: width * 0.012),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: width * 0.59,
                            height: height * 0.065,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isPhoneNumberEmpty
                                        ? const Color.fromARGB(255, 244, 92, 54)
                                        : _phoneFocusNode.hasFocus
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                              ),
                              borderRadius: BorderRadius.circular(
                                width * 0.019,
                              ),
                            ),
                            padding: EdgeInsets.only(
                              bottom:
                                  _phoneFocusNode.hasFocus ? 0 : width * 0.025,
                              left: width * 0.025,
                              top: width * 0.038,
                              right: 0,
                            ),
                            child: TextFormField(
                              enabled: _countryCodeController.text.isNotEmpty,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.number,
                              controller: _phoneNumberController,
                              textInputAction: TextInputAction.done,
                              onTapOutside: (_) {
                                if (_phoneNumberController.text.isEmpty) {
                                  isPhoneNumberEmpty = true;
                                }

                                setState(() {
                                  FocusScope.of(context).unfocus();
                                });
                              },
                              onChanged: (_) {
                                isPhoneNumberEmpty =
                                    _phoneNumberController.text.isEmpty;
                              },
                              showCursor: false,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(
                                  top: width * 0.05,
                                ),
                                labelText: 'Phone Number',
                                labelStyle: TextStyle(
                                  fontSize: width * 0.038,
                                  color:
                                      isPhoneNumberEmpty
                                          ? const Color.fromARGB(
                                            255,
                                            244,
                                            92,
                                            54,
                                          )
                                          : _phoneFocusNode.hasFocus
                                          ? Colors.blue
                                          : Colors.grey.shade500,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                hintText: 'Like (684) 733-1234',
                                hintStyle: TextStyle(
                                  fontSize: width * 0.038,
                                  color: Colors.grey.shade500.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                                constraints: BoxConstraints(
                                  minHeight: height * 0.065,
                                  maxHeight: height * 0.065,
                                  maxWidth: width * 0.539,
                                  minWidth: width * 0.539,
                                ),
                                suffixIcon:
                                    _phoneNumberController.text.isEmpty
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
                                        ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          if (isPhoneNumberEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                left: width * 0.04,
                                top: width * 0.007,
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: width * 0.03,
                                  color: const Color.fromARGB(255, 244, 92, 54),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: height * 0.011),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthPhoneAlternative(),
                      ),
                    );
                  },
                  child: Text(
                    'Can\'t find your country code?',
                    style: TextStyle(fontSize: 16, color: Colors.blue.shade400),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_phoneNumberController.text.isNotEmpty &&
                  _characterCount >= 7) {
                // final countryCode = removeEmojis(_countryCodeController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: Duration(seconds: 2),
                    content: Text(
                      'Please enter valid phone number to sign in',
                      style: TextStyle(
                        color: darkMode ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: width * 0.923,
              height: height * 0.058,
              decoration: BoxDecoration(
                color:
                    _characterCount >= 7
                        ? (darkMode
                            ? Color.fromARGB(255, 1, 105, 170)
                            : Color.fromARGB(255, 0, 134, 179))
                        : (darkMode
                            ? Color.fromARGB(255, 52, 168, 235)
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
                        _characterCount >= 7
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
          ),
        ],
      ),
    );
  }
}
