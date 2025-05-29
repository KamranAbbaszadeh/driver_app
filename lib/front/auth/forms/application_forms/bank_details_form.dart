import 'package:onemoretour/back/upload_files/bank_details/upload_bank_details.dart';
import 'package:onemoretour/db/user_data/store_role.dart';
import 'package:onemoretour/front/auth/forms/application_forms/upper_case_text_formatter.dart';
import 'package:onemoretour/front/displayed_items/intermediate_page_for_forms.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iban/iban.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BankDetailsForm extends ConsumerStatefulWidget {
  const BankDetailsForm({super.key});

  @override
  ConsumerState<BankDetailsForm> createState() => _BankDetailsFormState();
}

class _BankDetailsFormState extends ConsumerState<BankDetailsForm> {
  final ScrollController _scrollController = ScrollController();
  bool showTitle = false;
  final _addressController = TextEditingController();
  late FocusNode _addressFocusNode;
  bool isAdressEmpty = false;

  final _finCodeController = TextEditingController();
  late FocusNode _finCodeFocusNode;
  bool isFINCodeEmpty = false;
  bool isFINCodeValid = true;

  final _vATnumberController = TextEditingController();
  late FocusNode _vATnumberFocusNode;
  bool isVATnumberEmpty = false;
  bool isVATnumberValid = true;

  final _bankNameController = TextEditingController();
  late FocusNode _bankNameFocusNode;
  bool isBankNameEmpty = false;

  final _bankCodeController = TextEditingController();
  late FocusNode _bankCodeFocusNode;
  bool isBankCodeEmpty = false;
  bool isBankCodeValid = true;

  final _mHController = TextEditingController();
  late FocusNode _mHFocusNode;
  bool isMHEmpty = false;
  bool isMHValid = true;

  final _sWIFTController = TextEditingController();
  late FocusNode _sWIFTFocusNode;
  bool isSWIFTEmpty = false;
  bool isSWIFTValid = true;

  final _iBANController = TextEditingController();
  late FocusNode _iBANFocusNode;
  bool isIBANEmpty = false;
  bool isIbanValid = true;

  bool isValidCorrespondentAccount(String account) {
    if (account.isNotEmpty) {
      account = account.replaceAll(' ', '');
      final regex = RegExp(r'^[A-Z0-9]{20,34}$');
      return regex.hasMatch(account);
    }
    return true;
  }

  bool isValidSWIFT(String swift) {
    if (swift.isNotEmpty) {
      swift = swift.replaceAll(' ', '');
      return swift.length == 8 || swift.length == 11
          ? RegExp(r'^[A-Z0-9]+$').hasMatch(swift)
          : false;
    }
    return true;
  }

  bool isValidIban(String iban) {
    if (iban.isNotEmpty) {
      return isValid(iban);
    }
    return true;
  }

  bool isValidBankCode(String code) {
    if (code.isNotEmpty) {
      code = code.replaceAll(' ', '');
      final regex = RegExp(r'^\d{5,8}$');
      return regex.hasMatch(code);
    }
    return true;
  }

  bool isValidFINCode(String fin) {
    if (fin.isNotEmpty) {
      fin = fin.replaceAll(' ', '');
      final regex = RegExp(r'^[A-Z0-9]{7}$');
      return regex.hasMatch(fin);
    }
    return true;
  }

  bool isValidVATNumber(String vat) {
    if (vat.isNotEmpty) {
      vat = vat.replaceAll(' ', '');
      final regex = RegExp(r'^\d{10}$');
      return regex.hasMatch(vat);
    }
    return true;
  }

  Future<void> _saveTempData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('address', _addressController.text);
    await prefs.setString('fin', _finCodeController.text);
    await prefs.setString('vat', _vATnumberController.text);
    await prefs.setString('bankName', _bankNameController.text);
    await prefs.setString('bankCode', _bankCodeController.text);
    await prefs.setString('mh', _mHController.text);
    await prefs.setString('swift', _sWIFTController.text);
    await prefs.setString('iban', _iBANController.text);
  }

  Future<void> _loadTempData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();
      final isDeclined = doc.data()?['Personal & Car Details Decline'] == true;

      if (isDeclined) {
        final data = doc.data()!;
        _addressController.text = data['Address'] ?? '';
        _finCodeController.text = data['FIN'] ?? '';
        _vATnumberController.text = data['VAT'] ?? '';
        _bankNameController.text = data['Bank Name'] ?? '';
        _bankCodeController.text = data['Bank Code'] ?? '';
        _mHController.text = data['M.H'] ?? '';
        _sWIFTController.text = data['SWIFT'] ?? '';
        _iBANController.text = data['IBAN'] ?? '';
        return;
      }
    }

    _addressController.text = prefs.getString('address') ?? '';
    _finCodeController.text = prefs.getString('fin') ?? '';
    _vATnumberController.text = prefs.getString('vat') ?? '';
    _bankNameController.text = prefs.getString('bankName') ?? '';
    _bankCodeController.text = prefs.getString('bankCode') ?? '';
    _mHController.text = prefs.getString('mh') ?? '';
    _sWIFTController.text = prefs.getString('swift') ?? '';
    _iBANController.text = prefs.getString('iban') ?? '';
  }

  Future<void> _clearTempData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('address');
    await prefs.remove('fin');
    await prefs.remove('vat');
    await prefs.remove('bankName');
    await prefs.remove('bankCode');
    await prefs.remove('mh');
    await prefs.remove('swift');
    await prefs.remove('iban');
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 5 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_scrollController.offset <= 5 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });

    _addressFocusNode = FocusNode();

    _addressFocusNode.addListener(() {
      if (!_addressFocusNode.hasFocus) {
        _isEmpty(_addressController, 'Address');
      }
    });

    _addressController.addListener(() {
      setState(() {});
      _saveTempData();
    });

    _finCodeFocusNode = FocusNode();

    _finCodeFocusNode.addListener(() {
      if (!_finCodeFocusNode.hasFocus) {
        _isEmpty(_finCodeController, 'FIN');
      }
    });

    _finCodeController.addListener(() {
      setState(() {
        if (!isFINCodeEmpty) {
          isFINCodeValid = isValidFINCode(_finCodeController.text);
        }
      });
      _saveTempData();
    });

    _vATnumberFocusNode = FocusNode();

    _vATnumberFocusNode.addListener(() {
      if (!_vATnumberFocusNode.hasFocus) {
        _isEmpty(_vATnumberController, 'VAT Number');
      }
    });

    _vATnumberController.addListener(() {
      setState(() {
        if (!isVATnumberEmpty) {
          isVATnumberValid = isValidVATNumber(_vATnumberController.text);
        }
      });
      _saveTempData();
    });

    _bankNameFocusNode = FocusNode();

    _bankNameFocusNode.addListener(() {
      if (!_bankNameFocusNode.hasFocus) {
        _isEmpty(_bankNameController, 'Bank Name');
      }
    });

    _bankNameController.addListener(() {
      setState(() {});
      _saveTempData();
    });

    _bankCodeFocusNode = FocusNode();

    _bankCodeFocusNode.addListener(() {
      if (!_bankCodeFocusNode.hasFocus) {
        _isEmpty(_bankCodeController, 'Bank Code');
      }
    });

    _bankCodeController.addListener(() {
      setState(() {
        if (!isBankCodeEmpty) {
          isBankCodeValid = isValidBankCode(_bankCodeController.text);
        }
      });
      _saveTempData();
    });

    _mHFocusNode = FocusNode();

    _mHFocusNode.addListener(() {
      if (!_mHFocusNode.hasFocus) {
        _isEmpty(_mHController, 'MH');
      }
    });

    _mHController.addListener(() {
      setState(() {
        if (!isMHEmpty) {
          isMHValid = isValidCorrespondentAccount(_mHController.text);
        }
      });
      _saveTempData();
    });

    _sWIFTFocusNode = FocusNode();

    _sWIFTFocusNode.addListener(() {
      if (!_sWIFTFocusNode.hasFocus) {
        _isEmpty(_sWIFTController, 'SWIFT');
      }
    });

    _sWIFTController.addListener(() {
      setState(() {
        if (!isSWIFTEmpty) {
          isSWIFTValid = isValidSWIFT(_sWIFTController.text);
        }
      });
      _saveTempData();
    });

    _iBANFocusNode = FocusNode();

    _iBANFocusNode.addListener(() {
      if (!_iBANFocusNode.hasFocus) {
        _isEmpty(_iBANController, 'IBAN');
      }
    });

    _iBANController.addListener(() {
      setState(() {
        if (!isIBANEmpty) {
          isIbanValid = isValidIban(_iBANController.text);
        }
      });
      _saveTempData();
    });

    _loadTempData();
  }

  void _isEmpty(TextEditingController controller, String fieldName) {
    setState(() {
      if (controller.text.isEmpty) {
        if (fieldName == 'VAT Number') {
          isVATnumberEmpty = true;
        } else if (fieldName == 'Bank Name') {
          isBankNameEmpty = true;
        } else if (fieldName == 'Bank Code') {
          isBankCodeEmpty = true;
        } else if (fieldName == 'MH') {
          isMHEmpty = true;
        } else if (fieldName == 'SWIFT') {
          isSWIFTEmpty = true;
        } else if (fieldName == 'IBAN') {
          isIBANEmpty = true;
        } else if (fieldName == 'Address') {
          isAdressEmpty = true;
        } else if (fieldName == 'FIN') {
          isFINCodeEmpty = true;
        }
      } else {
        if (fieldName == 'VAT Number') {
          isVATnumberEmpty = false;
        } else if (fieldName == 'Bank Name') {
          isBankNameEmpty = false;
        } else if (fieldName == 'Bank Code') {
          isBankCodeEmpty = false;
        } else if (fieldName == 'MH') {
          isMHEmpty = false;
        } else if (fieldName == 'SWIFT') {
          isSWIFTEmpty = false;
        } else if (fieldName == 'IBAN') {
          isIBANEmpty = false;
        } else if (fieldName == 'Address') {
          isAdressEmpty = false;
        } else if (fieldName == 'FIN') {
          isFINCodeEmpty = false;
        }
      }
    });
  }

  bool _allFilledOut() {
    if (_addressController.text.isNotEmpty &&
        _finCodeController.text.isNotEmpty &&
        _vATnumberController.text.isNotEmpty &&
        _bankCodeController.text.isNotEmpty &&
        _bankNameController.text.isNotEmpty &&
        _mHController.text.isNotEmpty &&
        _sWIFTController.text.isNotEmpty &&
        _iBANController.text.isNotEmpty &&
        isIbanValid &&
        isBankCodeValid &&
        isFINCodeValid &&
        isIbanValid &&
        isMHValid &&
        isSWIFTValid &&
        isVATnumberValid) {
      return true;
    }
    return false;
  }

  Future<void> _submitForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;
    final doc =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
    final role = doc.data()?['Role'];

    Map<String, dynamic> bankDetails =
        role == "Guide"
            ? {
              'Address': _addressController.text,
              'FIN': _finCodeController.text,
              'VAT': _vATnumberController.text,
              'Bank Name': _bankNameController.text,
              'Bank Code': _bankCodeController.text,
              'M.H': _mHController.text,
              'SWIFT': _sWIFTController.text,
              'IBAN': _iBANController.text,
              'Personal & Car Details Decline': false,
            }
            : {
              'Address': _addressController.text,
              'FIN': _finCodeController.text,
              'VAT': _vATnumberController.text,
              'Bank Name': _bankNameController.text,
              'Bank Code': _bankCodeController.text,
              'M.H': _mHController.text,
              'SWIFT': _sWIFTController.text,
              'IBAN': _iBANController.text,
            };
    if (mounted) {
      await uploadBankDetails(
        bankDetails: bankDetails,
        userId: userId,
        context: context,
      );
    }
    await _clearTempData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose();

    _finCodeController.dispose();
    _finCodeFocusNode.dispose();

    _vATnumberController.dispose();
    _vATnumberFocusNode.dispose();

    _bankNameController.dispose();
    _bankNameFocusNode.dispose();

    _iBANFocusNode.dispose();
    _iBANController.dispose();

    _mHController.dispose();
    _mHFocusNode.dispose();

    _sWIFTController.dispose();
    _sWIFTFocusNode.dispose();

    _bankCodeController.dispose();
    _bankCodeFocusNode.dispose();
    super.dispose();
  }

  void _checkFields() {
    if (_addressController.text.isEmpty) {
      _isEmpty(_addressController, 'Address');
      _addressFocusNode.requestFocus();
      return;
    } else if (_finCodeController.text.isEmpty || !isFINCodeValid) {
      _isEmpty(_finCodeController, 'FIN');
      _finCodeFocusNode.requestFocus();
      return;
    } else if (_vATnumberController.text.isEmpty || !isVATnumberValid) {
      _isEmpty(_vATnumberController, 'VAT Number');
      _vATnumberFocusNode.requestFocus();
      return;
    } else if (_bankNameController.text.isEmpty) {
      _isEmpty(_bankNameController, 'Bank Name');
      _bankNameFocusNode.requestFocus();
      return;
    } else if (_bankCodeController.text.isEmpty || !isBankCodeValid) {
      _isEmpty(_bankCodeController, 'Bank Code');
      _bankCodeFocusNode.requestFocus();
      return;
    } else if (_mHController.text.isEmpty || !isMHValid) {
      _isEmpty(_mHController, 'MH');
      _mHFocusNode.requestFocus();
      return;
    } else if (_sWIFTController.text.isEmpty || !isSWIFTValid) {
      _isEmpty(_sWIFTController, 'SWIFT');
      _sWIFTFocusNode.requestFocus();
      return;
    } else if (_iBANController.text.isEmpty || !isIbanValid) {
      _isEmpty(_iBANController, 'IBAN');
      _iBANFocusNode.requestFocus();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleDetails = ref.watch(roleProvider);
    final role = roleDetails?['Role'] ?? '';
    String numOfPages = role == 'Guide' ? '3/3' : '3/4';
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
          opacity: showTitle ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
          child: Text(
            '$numOfPages Your Financial Details for Seamless Transactions',
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
                  '$numOfPages Your Financial Details for Seamless Transactions',
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
                  role == 'Guide'
                      ? 'Let\'s finalize your profile! Help us set up your account for payments and compliance by sharing your VAT, banking details, and other key information securely.'
                      : 'We\'re almost there! Help us set up your account for payments and compliance by sharing your VAT, banking details, and other key information securely.',
                ),
                SizedBox(height: height * 0.015),
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isAdressEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _addressFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        _addressFocusNode.hasFocus ||
                                _addressController.text.isNotEmpty
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
                          _addressFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_addressController, 'Address');
                        setState(() {
                          _addressFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _addressFocusNode,
                      onEditingComplete: () {
                        _addressFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_finCodeFocusNode);
                      },
                      controller: _addressController,
                      decoration: InputDecoration(
                        suffixIcon:
                            _addressFocusNode.hasFocus
                                ? _addressController.text.isEmpty
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
                                        _addressController.clear();
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
                        labelText: 'Registration address',
                        hintText:
                            'Bakı şəhəri, R.Behbudov küçəsi 13, mənzil 14',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isAdressEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _addressFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isAdressEmpty)
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
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isFINCodeEmpty || !isFINCodeValid
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _finCodeFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        _finCodeFocusNode.hasFocus ||
                                _finCodeController.text.isNotEmpty
                            ? 0
                            : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      maxLength: 7,
                      buildCounter:
                          (
                            BuildContext context, {
                            int? currentLength,
                            bool? isFocused,
                            int? maxLength,
                          }) => null,
                      onTap: () {
                        setState(() {
                          _finCodeFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_finCodeController, 'FIN');
                        setState(() {
                          _finCodeFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _finCodeFocusNode,
                      onEditingComplete: () {
                        _finCodeFocusNode.unfocus();
                        FocusScope.of(
                          context,
                        ).requestFocus(_vATnumberFocusNode);
                      },
                      controller: _finCodeController,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      ],
                      decoration: InputDecoration(
                        suffixIcon:
                            _finCodeFocusNode.hasFocus
                                ? _finCodeController.text.isEmpty
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
                                        _finCodeController.clear();
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
                        labelText: 'FIN CODE "Personal identification number"',
                        hintText: '94FMDDD',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isFINCodeEmpty || !isFINCodeValid
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _finCodeFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isFINCodeEmpty || !isFINCodeValid)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      isFINCodeEmpty ? "Required" : "Invalid FIN Code",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isVATnumberEmpty || !isVATnumberValid
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _vATnumberFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        _vATnumberFocusNode.hasFocus ||
                                _vATnumberController.text.isNotEmpty
                            ? 0
                            : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      maxLength: 10,
                      buildCounter:
                          (
                            BuildContext context, {
                            int? currentLength,
                            bool? isFocused,
                            int? maxLength,
                          }) => null,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      onEditingComplete: () {
                        _vATnumberFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_bankNameFocusNode);
                      },
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
                        hintText: '1245468891',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isVATnumberEmpty || !isVATnumberValid
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
                if (isVATnumberEmpty || !isVATnumberValid)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      isVATnumberEmpty ? "Required" : "Invalid VAT Number",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isBankNameEmpty
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _bankNameFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        _bankNameFocusNode.hasFocus ||
                                _bankNameController.text.isNotEmpty
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
                          _bankNameFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_bankNameController, 'Bank Name');
                        setState(() {
                          _bankNameFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _bankNameFocusNode,
                      onEditingComplete: () {
                        _bankNameFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_bankCodeFocusNode);
                      },
                      controller: _bankNameController,
                      decoration: InputDecoration(
                        suffixIcon:
                            _bankNameFocusNode.hasFocus
                                ? _bankNameController.text.isEmpty
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
                                        _bankNameController.clear();
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
                        labelText: 'Bank Name',
                        hintText: 'Kapital Bank ASC Merkez filiali',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isBankNameEmpty
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _bankNameFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isBankNameEmpty)
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
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isBankCodeEmpty || !isBankCodeValid
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _bankCodeFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        _bankCodeFocusNode.hasFocus ||
                                _bankCodeController.text.isNotEmpty
                            ? 0
                            : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      maxLength: 8,
                      buildCounter:
                          (
                            BuildContext context, {
                            int? currentLength,
                            bool? isFocused,
                            int? maxLength,
                          }) => null,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onTap: () {
                        setState(() {
                          _bankCodeFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_bankCodeController, 'Bank Code');
                        setState(() {
                          _bankCodeFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _bankCodeFocusNode,
                      onEditingComplete: () {
                        _bankCodeFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_mHFocusNode);
                      },
                      controller: _bankCodeController,
                      decoration: InputDecoration(
                        suffixIcon:
                            _bankCodeFocusNode.hasFocus
                                ? _bankCodeController.text.isEmpty
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
                                        _bankCodeController.clear();
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
                        labelText: 'Bank Code',
                        hintText: '533345',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isBankCodeEmpty || !isBankCodeValid
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _bankCodeFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isBankCodeEmpty || !isBankCodeValid)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      isBankCodeEmpty
                          ? "Required"
                          : "Invalid Bank Code format.",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isMHEmpty || !isMHValid
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _mHFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        _mHFocusNode.hasFocus || _mHController.text.isNotEmpty
                            ? 0
                            : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      maxLength: 34,
                      buildCounter:
                          (
                            BuildContext context, {
                            int? currentLength,
                            bool? isFocused,
                            int? maxLength,
                          }) => null,

                      onTap: () {
                        setState(() {
                          _mHFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_mHController, 'MH');
                        setState(() {
                          _mHFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _mHFocusNode,
                      onEditingComplete: () {
                        _mHFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_sWIFTFocusNode);
                      },
                      controller: _mHController,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      ],
                      decoration: InputDecoration(
                        suffixIcon:
                            _mHFocusNode.hasFocus
                                ? _mHController.text.isEmpty
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
                                        _mHController.clear();
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
                        labelText: 'M.H:',
                        hintText: 'AZ89NABR01576100000000002356',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isMHEmpty || !isMHValid
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _mHFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isMHEmpty || !isMHValid)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      isMHEmpty
                          ? "Required"
                          : "Invalid Correspondent Bank Account (Müxbir Hesab) format.",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.015),
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isSWIFTEmpty || !isSWIFTValid
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _sWIFTFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        _sWIFTFocusNode.hasFocus ||
                                _sWIFTController.text.isNotEmpty
                            ? 0
                            : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      maxLength: 11,
                      buildCounter:
                          (
                            BuildContext context, {
                            int? currentLength,
                            bool? isFocused,
                            int? maxLength,
                          }) => null,
                      onTap: () {
                        setState(() {
                          _sWIFTFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_sWIFTController, 'SWIFT');
                        setState(() {
                          _sWIFTFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _sWIFTFocusNode,
                      onEditingComplete: () {
                        _sWIFTFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_iBANFocusNode);
                      },
                      controller: _sWIFTController,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      ],
                      decoration: InputDecoration(
                        suffixIcon:
                            _sWIFTFocusNode.hasFocus
                                ? _sWIFTController.text.isEmpty
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
                                        _sWIFTController.clear();
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
                        labelText: 'SWIFT',
                        hintText: 'AIIRDAZ9',

                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isSWIFTEmpty || !isSWIFTValid
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _sWIFTFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSWIFTEmpty || !isSWIFTValid)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      isSWIFTEmpty ? "Required" : "Invalid SWIFT Code format.",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),

                SizedBox(height: height * 0.015),
                Container(
                  width: width,
                  height: height * 0.065,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isIBANEmpty || !isIbanValid
                              ? const Color.fromARGB(255, 244, 92, 54)
                              : _iBANFocusNode.hasFocus
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(width * 0.019),
                  ),
                  padding: EdgeInsets.only(
                    bottom:
                        _iBANFocusNode.hasFocus ||
                                _iBANController.text.isNotEmpty
                            ? 0
                            : width * 0.025,
                    left: width * 0.025,
                    top: width * 0.025,
                    right: width * 0.025,
                  ),
                  child: Center(
                    child: TextField(
                      maxLength: 34,
                      buildCounter:
                          (
                            BuildContext context, {
                            int? currentLength,
                            bool? isFocused,
                            int? maxLength,
                          }) => null,
                      onTap: () {
                        setState(() {
                          _iBANFocusNode.requestFocus();
                        });
                      },
                      onTapOutside: (_) {
                        _isEmpty(_iBANController, 'IBAN');
                        setState(() {
                          _iBANFocusNode.unfocus();
                        });
                      },
                      showCursor: false,
                      focusNode: _iBANFocusNode,
                      onEditingComplete: () {
                        _iBANFocusNode.unfocus();
                      },
                      controller: _iBANController,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      ],
                      decoration: InputDecoration(
                        suffixIcon:
                            _iBANFocusNode.hasFocus
                                ? _iBANController.text.isEmpty
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
                                        _iBANController.clear();
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
                        labelText: 'IBAN',
                        hintText: 'AZ93AIID56676634995921783406',
                        hintStyle: TextStyle(
                          fontSize: width * 0.038,
                          color: Colors.grey.shade500.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        labelStyle: TextStyle(
                          fontSize: width * 0.038,
                          color:
                              isIBANEmpty || !isIbanValid
                                  ? const Color.fromARGB(255, 244, 92, 54)
                                  : _iBANFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isIBANEmpty || !isIbanValid)
                  Padding(
                    padding: EdgeInsets.only(
                      left: width * 0.027,
                      top: width * 0.007,
                    ),
                    child: Text(
                      isIBANEmpty
                          ? "Required"
                          : "Invalid International Bank Account Number (IBAN) format.",
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: const Color.fromARGB(255, 244, 92, 54),
                      ),
                    ),
                  ),

                SizedBox(height: height * 0.025),
                GestureDetector(
                  onTap: () async {
                    if (_allFilledOut()) {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          child: IntermediateFormPage(
                            isFromPersonalDataForm: false,
                            isFromBankDetailsForm: true,
                            isFromCarDetailsForm: false,
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
                        role == 'Guide' ? 'Submit' : 'Next',
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
