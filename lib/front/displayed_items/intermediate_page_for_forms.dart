import 'package:onemoretour/back/tools/loading_notifier.dart';
import 'package:onemoretour/db/user_data/store_role.dart';
import 'package:onemoretour/front/auth/forms/application_forms/bank_details_form.dart';
import 'package:onemoretour/front/auth/forms/application_forms/car_details_switcher.dart';
import 'package:onemoretour/front/auth/forms/application_forms/certificates_details.dart';
import 'package:onemoretour/front/auth/waiting_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:onemoretour/front/intro/welcome_page.dart';
import 'package:page_transition/page_transition.dart';

class IntermediateFormPage extends ConsumerStatefulWidget {
  final bool isFromPersonalDataForm;
  final bool isFromBankDetailsForm;
  final bool isFromCertificateDetailsForm;
  final bool isFromCarDetailsSwitcher;
  final bool isFromCarDetailsForm;
  final bool isFromProfilePage;
  final Future<void> Function() backgroundProcess;
  const IntermediateFormPage({
    super.key,
    required this.isFromPersonalDataForm,
    required this.isFromBankDetailsForm,
    required this.isFromCarDetailsForm,
    required this.isFromCertificateDetailsForm,
    required this.isFromCarDetailsSwitcher,
    required this.isFromProfilePage,
    required this.backgroundProcess,
  });

  @override
  ConsumerState<IntermediateFormPage> createState() =>
      _IntermediateFormPageState();
}

class _IntermediateFormPageState extends ConsumerState<IntermediateFormPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasProcessed = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final isLoading = ref.watch(loadingProvider);
    final roleDetails = ref.watch(roleProvider);
    final role = roleDetails?['Role'] ?? '';
    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      body: Center(
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child:
              isLoading
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SpinKitSpinningLines(
                        size: width * 0.45,
                        color:
                            darkMode
                                ? const Color(0xFF0169AA)
                                : const Color(0xFF34A8EB),
                        key: const ValueKey('spinner'),
                      ),
                      SizedBox(height: height * 0.025),
                      Text(
                        "Processing your information...",
                        style: GoogleFonts.cabin(
                          color:
                              darkMode
                                  ? const Color(0xFF0169AA)
                                  : const Color(0xFF34A8EB),
                          fontSize: width * 0.061,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                  : Lottie.asset(
                    darkMode
                        ? 'assets/int_p_check_dark.json'
                        : 'assets/int_p_check_light.json',
                    controller: _controller,
                    key: const ValueKey('animation'),
                    onLoaded: (composition) async {
                      if (_hasProcessed) return;
                      _hasProcessed = true;
                      _controller
                        ..duration = composition.duration
                        ..reset();

                      ref.read(loadingProvider.notifier).startLoading();
                      try {
                        await widget.backgroundProcess();
                        ref.read(loadingProvider.notifier).stopLoading();

                        await _controller.forward();

                        if (context.mounted) {
                          if (widget.isFromBankDetailsForm) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                child:
                                    role == 'Guide'
                                        ? WaitingPage()
                                        : CarDetailsSwitcher(),
                              ),
                              (route) => false,
                            );
                          } else if (widget.isFromPersonalDataForm) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                child: CertificatesDetails(role: role),
                              ),
                              (route) => false,
                            );
                          } else if (widget.isFromCertificateDetailsForm) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                child: BankDetailsForm(),
                              ),
                              (route) => false,
                            );
                          } else if (widget.isFromCarDetailsForm) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                child: WaitingPage(),
                              ),
                              (route) => false,
                            );
                          } else if (widget.isFromCarDetailsSwitcher) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                child: WaitingPage(),
                              ),
                              (route) => false,
                            );
                          } else if (widget.isFromProfilePage) {
                            void popMultiple(BuildContext context, int count) {
                              for (int i = 0; i < count; i++) {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              }
                            }

                            popMultiple(context, 2);
                          }
                        }
                      } catch (e) {
                        ref.read(loadingProvider.notifier).stopLoading();

                        if (context.mounted) {
                          final rawMessage = e.toString();
                          final cleanedMessage = rawMessage.replaceFirst(
                            RegExp(r'^\[.*?\] '),
                            '',
                          );
                          await showDialog(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      width * 0.04,
                                    ),
                                  ),
                                  backgroundColor:
                                      darkMode
                                          ? const Color(0xFF1C1C1E)
                                          : Colors.white,
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.redAccent,
                                      ),
                                      SizedBox(width: width * 0.02),
                                      Text(
                                        'Operation Failed',
                                        style: GoogleFonts.cabin(
                                          color:
                                              darkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    'An unexpected error occurred:\n\n$cleanedMessage',
                                    style: GoogleFonts.cabin(
                                      color:
                                          darkMode
                                              ? Colors.white70
                                              : Colors.black87,
                                      fontSize: width * 0.04,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            darkMode
                                                ? Colors.redAccent.shade100
                                                : Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.04,
                                          vertical: height * 0.014,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            width * 0.02,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                      },
                                      child: Text(
                                        'Return',
                                        style: GoogleFonts.cabin(
                                          fontWeight: FontWeight.w600,
                                          fontSize: width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );

                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                child: WelcomePage(),
                              ),
                              (route) => false,
                            );
                          }
                        }
                      }
                    },
                  ),
        ),
      ),
    );
  }
}
