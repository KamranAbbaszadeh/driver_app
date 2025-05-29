import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/tools/loading_notifier.dart';
import 'package:onemoretour/front/auth/waiting_page.dart';
import 'package:onemoretour/back/tools/validate_email.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthEmail extends ConsumerStatefulWidget {
  const AuthEmail({super.key});

  @override
  ConsumerState<AuthEmail> createState() => _AuthState();
}

class _AuthState extends ConsumerState<AuthEmail> {
  final TextEditingController _emailController = TextEditingController();
  late FocusNode _emailFocusNode;
  bool isEmpty = false;
  bool isValid = true;

  final _passwordController = TextEditingController();
  late FocusNode _passwordFocusNode;
  bool passwordObscure = true;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        // _isEmpty(_passwordController, 'password');
        setState(() {
          passwordObscure = true;
        });
      }
    });

    _passwordController.addListener(() {
      setState(() {});
    });
  }

  void _validateEmail(String value) {
    setState(() {
      isEmpty = value.isEmpty;
      isValid = validateEmail(value);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordFocusNode.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final isLoading = ref.watch(loadingProvider);
    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        toolbarHeight: height * 0.065,
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: height * 0.762,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(width * 0.02),
                      child: Text(
                        'Please sign with your email address',
                        style: GoogleFonts.daysOne(
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.066,
                            color: darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.010),
                    Padding(
                      padding: EdgeInsets.all(width * 0.02),
                      child: Text(
                        'Please input your email & password to sign in!',
                        style: TextStyle(fontSize: width * 0.04),
                      ),
                    ),
                    SizedBox(height: height * 0.001),
                    Padding(
                      padding: EdgeInsets.all(width * 0.02),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: width,
                            height: height * 0.065,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isEmpty || !isValid
                                        ? const Color.fromARGB(255, 244, 92, 54)
                                        : _emailFocusNode.hasFocus
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                              ),
                              borderRadius: BorderRadius.circular(
                                width * 0.019,
                              ),
                            ),
                            padding: EdgeInsets.only(
                              bottom:
                                  _emailController.text.isNotEmpty
                                      ? 0
                                      : width * 0.025,
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
                                  if (_emailController.text.isEmpty) {
                                    setState(() {
                                      isEmpty = true;
                                    });
                                  }
                                  setState(() {
                                    _emailFocusNode.unfocus();
                                  });
                                },
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
                                          ? _emailController.text.isEmpty
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
                                        isEmpty || !isValid
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
                          if (isEmpty)
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
                          if (!isValid && !isEmpty)
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
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.02),
                      child: Container(
                        width: width,
                        height: height * 0.065,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _passwordFocusNode.hasFocus
                                    ? Colors.blue
                                    : Colors.grey.shade400,
                          ),
                          borderRadius: BorderRadius.circular(width * 0.019),
                        ),
                        padding: EdgeInsets.only(
                          bottom:
                              _passwordController.text.isNotEmpty
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
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                fontSize: width * 0.038,
                                color:
                                    _passwordFocusNode.hasFocus
                                        ? Colors.blue
                                        : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  try {
                    ref.read(loadingProvider.notifier).startLoading();
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: _emailController.text.trim().toLowerCase(),
                      password: _passwordController.text.trim(),
                    );
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    final userId = user.uid;

                    FirebaseApi.instance.saveFCMToken(userId);

                    ref.read(loadingProvider.notifier).stopLoading();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => WaitingPage()),
                        (route) => false,
                      );
                    }
                  } catch (_) {
                    ref.read(loadingProvider.notifier).stopLoading();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Email or password is incorrect"),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: width * 0.923,
                  height: height * 0.058,
                  decoration: BoxDecoration(
                    color:
                        darkMode
                            ? Color.fromARGB(255, 52, 168, 235)
                            : Color.fromARGB(177, 0, 134, 179),
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
                              'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: width * 0.04,
                                color:
                                    darkMode
                                        ? const Color.fromARGB(255, 0, 0, 0)
                                        : const Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                              ),
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
