// Displays a modal bottom sheet for selecting one or more vehicle types.
// Uses the WoltModalSheet package and supports both single and multiple selection modes.
// Updates the provided [selectedVehicles] set based on user interaction.
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Shows a vehicle type picker modal using WoltModalSheet.
/// Allows users to choose from a predefined list of vehicle types.
/// Supports both single and multi-select modes, depending on [singleSelection].
/// Updates the provided [selectedVehicles] set with the user's final selection on "Done".
Future<void> showVehicleTypePicker(
  BuildContext context,

  Set<String> selectedVehicles, {
  bool singleSelection = false,
  String vehicleType = "",
}) async {
  final darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  final width = MediaQuery.of(context).size.width;

  final vehicleTypes = ['Sedan', 'Minivan', 'SUV', 'Bus'];

  final Set<String> currentSelection = Set<String>.from(selectedVehicles);

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
              'Select your vehicle type',
              style: TextStyle(
                fontSize: width * 0.04,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailingNavBarWidget: TextButton(
              onPressed: () {
                Navigator.of(modalSheetContext).pop();
                selectedVehicles
                  ..clear()
                  ..addAll(currentSelection);
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
                  StatefulBuilder(
                    builder: (context, setState) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final vehicle = vehicleTypes[index];
                          final isChecked =
                              singleSelection
                                  ? currentSelection.length == 1 &&
                                      currentSelection.contains(vehicle)
                                  : currentSelection.contains(vehicle);

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
                                      if (singleSelection) {
                                        currentSelection
                                          ..clear()
                                          ..add(vehicle);
                                      } else {
                                        currentSelection.add(vehicle);
                                      }
                                    } else {
                                      currentSelection.remove(vehicle);
                                    }
                                  });
                                },
                              ),
                            ),
                            title: Text(
                              vehicle,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onTap: () {
                              setState(() {
                                if (isChecked) {
                                  currentSelection.remove(vehicle);
                                } else {
                                  if (singleSelection) {
                                    currentSelection
                                      ..clear()
                                      ..add(vehicle);
                                  } else {
                                    currentSelection.add(vehicle);
                                  }
                                }
                              });
                            },
                          );
                        }, childCount: vehicleTypes.length),
                      );
                    },
                  ),
                ],
          ),
        ],
  );
}
