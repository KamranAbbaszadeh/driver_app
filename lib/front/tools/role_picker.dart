import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

Future<void> showRolePicker(
    BuildContext context, TextEditingController selectedRole) async {
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  final width = MediaQuery.of(context).size.width;

  final roles = [
    'Driver',
    'Guide',
    'Driver Cum Guide',
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
          'Select your role',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        mainContentSliversBuilder: (context) => [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
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
              },
              childCount: roles.length,
            ),
          ),
        ],
      )
    ],
  );
}
