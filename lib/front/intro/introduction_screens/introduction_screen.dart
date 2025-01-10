import 'package:driver_app/front/intro/introduction_screens/introduction_screen_model.dart';
import 'package:driver_app/front/intro/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final PageController pageController = PageController();
  int currentIndex = 0;

  _storeIntroductionScreen() async {
    int isViewed = 0;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('IntroScreen', isViewed);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Flexible(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: screens.length,
                  itemBuilder: (context, index) {
                    final items = screens[index];
                    return Column(
                      children: [
                        SizedBox(height: height * 0.234),
                        SizedBox(
                          height: height * 0.422,
                          child: Center(
                            child: Lottie.asset(
                              screens[index].lottieURL,
                              fit: BoxFit.fill,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.058),
                        Text(
                          items.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.076,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: height * 0.058),
                        Text(
                          items.subTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: width * 0.045, color: Colors.white54),
                        ),
                      ],
                    );
                  },
                  onPageChanged: (value) {
                    setState(() {
                      currentIndex = value;
                    });
                  },
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  currentIndex != 0
                      ? SizedBox(
                        width: width * 0.178,
                        child: TextButton(
                          onPressed: () {
                            pageController.previousPage(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.linear,
                            );
                          },
                          child: Text(
                            'Prev',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      : SizedBox(width: width * 0.178),
                  Spacer(),
                  for (int index = 0; index < screens.length; index++)
                    dotIndicator(isSelected: index == currentIndex),
                  Spacer(),
                  SizedBox(
                    width: width * 0.178,
                    child: TextButton(
                      onPressed: () async {
                        if (currentIndex == screens.length - 1) {
                          await _storeIntroductionScreen();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WelcomePage(),
                              ),
                            );
                          }
                        }
                        pageController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.linear,
                        );
                      },
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.058),
            ],
          ),
        ],
      ),
    );
  }

  Widget dotIndicator({required bool isSelected}) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(right: width * 0.017),
      child: AnimatedContainer(
        duration: Duration(microseconds: 500),
        height: isSelected ? height * 0.009 : height * 0.007,
        width: isSelected ? width * 0.02 : width * 0.015,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.white : Colors.white24,
        ),
      ),
    );
  }
}
