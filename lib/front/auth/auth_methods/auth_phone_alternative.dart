import 'package:flutter/material.dart';

class AuthPhoneAlternative extends StatefulWidget {
  const AuthPhoneAlternative({super.key});

  @override
  State<AuthPhoneAlternative> createState() => _AuthState();
}

class _AuthState extends State<AuthPhoneAlternative> {
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  int _characterCount = 0;
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

    final regex = RegExp(r'^(?=.*\+)');

    final plusCheck = regex.hasMatch(_phoneNumberController.text);

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
          SizedBox(height: height * 0.035),
          Padding(
            padding: EdgeInsets.all(width * 0.02),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: width * 0.923,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          _phoneFocusNode.hasFocus
                              ? const Color.fromARGB(255, 33, 150, 243)
                              : const Color.fromARGB(255, 158, 158, 158),
                    ),
                    borderRadius: BorderRadius.circular(7.5),
                  ),
                  padding: EdgeInsets.only(
                    bottom: width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: 0,
                  ),
                  child: TextFormField(
                    focusNode: _phoneFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    controller: _phoneNumberController,
                    textInputAction: TextInputAction.done,
                    showCursor: true,
                    cursorHeight: height * 0.02,
                    cursorColor:
                        darkMode
                            ? Color.fromARGB(255, 1, 105, 170)
                            : Color.fromARGB(255, 0, 134, 179),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(top: width * 0.05),
                      labelText: 'Phone Number (international format)',
                      labelStyle: TextStyle(
                        fontSize: width * 0.038,
                        color:
                            _phoneFocusNode.hasFocus
                                ? const Color.fromARGB(255, 33, 150, 243)
                                : const Color.fromARGB(255, 158, 158, 158),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      hintText: 'eg. +358411235522',
                      hintStyle: TextStyle(
                        fontSize: width * 0.038,
                        color: const Color.fromARGB(255, 158, 158, 158),
                        fontWeight: FontWeight.w600,
                      ),
                      constraints: BoxConstraints(
                        minHeight: height * 0.07,
                        maxHeight: height * 0.07,
                        maxWidth: width * 0.844,
                        minWidth: width * 0.844,
                      ),
                      suffixIcon:
                          _phoneNumberController.text.isEmpty
                              ? Icon(
                                Icons.cancel_outlined,
                                size: 30,
                                color: Colors.grey.shade500.withValues(
                                  alpha: 0.5,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.011),
          GestureDetector(
            onTap: () {
              if (_phoneNumberController.text.isNotEmpty &&
                  _characterCount >= 7 &&
                  plusCheck) {
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
              height: height * 0.065,
              decoration: BoxDecoration(
                color:
                    _characterCount >= 7 && plusCheck
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
                        _characterCount >= 7 && plusCheck
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
