// Displays a modal bottom sheet for selecting a role (Driver, Guide, or Driver Cum Guide).
// Uses the WoltModalSheet package to render a scrollable role list with tappable items.
// Updates the provided TextEditingController with the selected role.
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Shows a role picker modal using WoltModalSheet.
/// Updates the [selectedRole] controller when the user selects a role option.
/// Supports dark mode and adjusts UI sizing based on screen width.
Future<void> showRolePicker(
  BuildContext context,
  TextEditingController selectedRole,
) async {
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  final width = MediaQuery.of(context).size.width;

  final roles = ['Driver', 'Guide', 'Driver Cum Guide'];

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
              'Select your role',
              style: TextStyle(
                fontSize: width * 0.04,
                fontWeight: FontWeight.w700,
              ),
            ),
            mainContentSliversBuilder:
                (context) => [
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final role = roles[index];

                      return StatefulBuilder(
                        builder: (context, setState) {
                          return ListTile(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            selectedColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            horizontalTitleGap: width * 0.005,
                            title: Text(
                              role,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onTap: () {
                              setState(() {
                                selectedRole.text = role;
                              });
                              Navigator.of(modalSheetContext).pop();
                            },
                          );
                        },
                      );
                    }, childCount: roles.length),
                  ),
                ],
          ),
        ],
  );
}
