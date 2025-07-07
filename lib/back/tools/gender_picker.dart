// Displays a modal bottom sheet for gender selection using the WoltModalSheet package.
// Allows the user to select between 'Male' and 'Female' and updates the provided TextEditingController.
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Shows a gender picker modal using WoltModalSheet.
/// Updates the [selectedGender] controller when the user selects a gender option.
/// Adjusts UI based on dark/light mode and screen width.
Future<void> showGenderPicker(
  BuildContext context,
  TextEditingController selectedGender,
) async {
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  final width = MediaQuery.of(context).size.width;

  final genderType = ['Male', 'Female'];

  await WoltModalSheet.show(
    context: context,
    pageListBuilder:
        (modalSheetContext) => [
          SliverWoltModalSheetPage(
            backgroundColor:
                darkMode ? const Color.fromARGB(255, 30, 29, 29) : Colors.white,
            surfaceTintColor: darkMode ? Colors.black : Colors.white,
            hasTopBarLayer: true,
            isTopBarLayerAlwaysVisible: true,
            topBarTitle: Text(
              'Select your gender',
              style: TextStyle(
                fontSize: width * 0.04,
                fontWeight: FontWeight.w700,
              ),
            ),
            mainContentSliversBuilder:
                (context) => [
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
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
                    }, childCount: genderType.length),
                  ),
                ],
          ),
        ],
  );
}
