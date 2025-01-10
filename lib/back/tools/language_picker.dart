import 'package:driver_app/back/tools/language_list.dart';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

Future<void> showLanguangePicker(
  BuildContext context,
  Set<String> selectedLanguages,
) async {
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  final width = MediaQuery.of(context).size.width;

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
              'Languange spoken',
              style: TextStyle(
                fontSize: width * 0.04,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailingNavBarWidget: TextButton(
              onPressed: () {
                Navigator.of(modalSheetContext).pop();
              },
              child: Text(
                'Done',
                style: TextStyle(
                  fontSize: width * 0.033,
                  color: const Color.fromARGB(255, 33, 152, 243),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            mainContentSliversBuilder:
                (context) => [
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final language = languages[index];
                      final languageName = language['name']!;

                      return StatefulBuilder(
                        builder: (context, setState) {
                          final isChecked = selectedLanguages.contains(
                            languageName,
                          );

                          return ListTile(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            selectedColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            horizontalTitleGap: width * 0.005,
                            leading: Transform.scale(
                              scale: width * 0.003,
                              child: Checkbox(
                                value: isChecked,
                                side: BorderSide(
                                  color: const Color.fromARGB(
                                    255,
                                    33,
                                    152,
                                    243,
                                  ),
                                ),
                                activeColor: const Color.fromARGB(
                                  255,
                                  33,
                                  152,
                                  243,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedLanguages.add(languageName);
                                    } else {
                                      selectedLanguages.remove(languageName);
                                    }
                                  });
                                },
                              ),
                            ),
                            title: Text(
                              languageName,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onTap: () {
                              setState(() {
                                if (isChecked) {
                                  selectedLanguages.remove(languageName);
                                } else {
                                  selectedLanguages.add(languageName);
                                }
                              });
                            },
                          );
                        },
                      );
                    }, childCount: languages.length),
                  ),
                ],
          ),
        ],
  );
}
