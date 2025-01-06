import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

Future<void> showGenderPicker(
    BuildContext context, TextEditingController selectedGender) async {
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  final width = MediaQuery.of(context).size.width;

  final genderType = [
    'Male',
    'Female',
  ];

  await WoltModalSheet.show(
    context: context,
    pageListBuilder: (modalSheetContext) => [
      SliverWoltModalSheetPage(
        backgroundColor:
            darkMode ? const Color.fromARGB(255, 30, 29, 29) : Colors.white,
        surfaceTintColor: darkMode ? Colors.black : Colors.white,
        hasTopBarLayer: true,
        isTopBarLayerAlwaysVisible: true,
        topBarTitle: Text(
          'Select your gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        mainContentSliversBuilder: (context) => [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final gender = genderType[index];

                return StatefulBuilder(
                  builder: (context, setState) {
                    return ListTile(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      selectedColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      horizontalTitleGap: width * 0.005,
                      title: Text(
                        gender,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        setState(() {
                          selectedGender.text = gender;
                        });
                        Navigator.of(modalSheetContext).pop();
                      },
                    );
                  },
                );
              },
              childCount: genderType.length,
            ),
          ),
        ],
      )
    ],
  );
}
