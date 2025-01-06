import 'package:driver_app/front/intro/terms_draft.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Terms extends StatelessWidget {
  const Terms({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    TextStyle defaultStyle =
        TextStyle(fontSize: 13, color: const Color.fromARGB(255, 0, 0, 0));
    TextStyle paragraphStyle = GoogleFonts.daysOne(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 0, 0, 0));
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: darkMode
            ? const Color.fromARGB(255, 0, 0, 0)
            : const Color.fromARGB(255, 255, 255, 255),
        leading: Padding(
          padding: const EdgeInsets.only(top: 15, left: 5),
          child: Text(
            'Terms & Conditions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leadingWidth: width / 1.5,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: 15,
                color: const Color.fromARGB(255, 33, 150, 243),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: SizedBox(
          child: Column(
            children: [
              Container(
                width: width,
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(width * 0.04),
                        bottomRight: Radius.circular(width * 0.04))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(width * 0.04),
                      child: Text(
                        'User Terms of Service - Azerbaijan',
                        style: GoogleFonts.daysOne(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph1,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description1,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph2,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description2,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph3,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description3,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph4,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description4,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph5,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description5,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph6,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description6,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph7,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description7,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph8,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description8,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph9,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description9,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph10,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description10,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph11,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description11,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph12,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description12,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph13,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description13,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph14,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description14,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph15,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description15,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph16,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description16,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph17,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description17,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          paragraph18,
                          style: paragraphStyle,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(
                        description18,
                        style: defaultStyle,
                        softWrap: true,
                      ),
                    ),
                    SizedBox(
                      height: height * 0.02,
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.2)
            ],
          ),
        ),
      ),
    );
  }
}
