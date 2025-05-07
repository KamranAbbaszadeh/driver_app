import 'package:driver_app/back/tools/loading_notifier.dart';
import 'package:driver_app/db/user_data/store_role.dart';
import 'package:driver_app/front/auth/forms/application_forms/bank_details_form.dart';
import 'package:driver_app/front/auth/forms/application_forms/car_details_switcher.dart';
import 'package:driver_app/front/auth/forms/application_forms/certificates_details.dart';
import 'package:driver_app/front/auth/waiting_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lottie/lottie.dart';
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
                  ? SpinKitThreeBounce(
                    color:
                        darkMode
                            ? const Color(0xFF0169AA)
                            : const Color(0xFF34A8EB),
                    key: const ValueKey('spinner'),
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
                    },
                  ),
        ),
      ),
    );
  }
}
