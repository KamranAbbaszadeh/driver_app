// A custom calendar widget for selecting dates within a ride's available range.
import 'package:onemoretour/front/tools/ride_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

/// Displays a calendar allowing users to select a date within the ride's range.
/// Notifies the parent widget of the selected day using a callback.
class DatePicker extends StatefulWidget {
  final Ride ride;
  final Function(DateTime) updateSelectedDay;
  const DatePicker({
    super.key,
    required this.ride,
    required this.updateSelectedDay,
  });

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  late DateTime selectedDate;

  // Initializes the selected date to the ride's start date.
  @override
  void initState() {
    super.initState();
    selectedDate = widget.ride.startDate.toDate();
  }

  // Builds the calendar UI with styling and selection logic.
  @override
  Widget build(BuildContext context) {
    // Detect dark or light theme.
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    // Get device height for responsive layout.
    final height = MediaQuery.of(context).size.height;
    // Get device width for responsive layout.
    final width = MediaQuery.of(context).size.width;
    final ride = widget.ride;
    // Wrap calendar in a styled container with height and padding.
    return Container(
      height: height * 0.13,
      padding: EdgeInsets.symmetric(vertical: height * 0.02),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(width * 0.076),
          topRight: Radius.circular(width * 0.076),
        ),
      ),
      child: TableCalendar(
        // Set calendar starting day of week based on ride's start date.
        startingDayOfWeek:
            ride.startDate.toDate().weekday == 1
                ? StartingDayOfWeek.sunday
                : StartingDayOfWeek.values[ride.startDate.toDate().weekday - 2],
        focusedDay: selectedDate,
        firstDay: ride.startDate.toDate(),
        lastDay: ride.endDate.toDate(),
        calendarFormat: CalendarFormat.week,
        rangeStartDay: ride.startDate.toDate(),
        rangeEndDay: ride.endDate.toDate(),

        // Update selected day and notify parent via callback.
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            selectedDate = selectedDay;
            widget.updateSelectedDay(selectedDay);
          });
        },

        headerVisible: false,
        // Mark the currently selected day.
        selectedDayPredicate: (day) {
          return isSameDay(selectedDate, day);
        },
        // Set font styles for weekday and weekend headers.
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
          weekendStyle: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
        ),
        // Configure styles for calendar cells, selection, and range highlighting.
        calendarStyle: CalendarStyle(
          defaultTextStyle: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
          withinRangeTextStyle: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
          rangeEndTextStyle: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
          rangeStartTextStyle: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
          rangeEndDecoration:
              darkMode
                  ? BoxDecoration(color: Colors.black, shape: BoxShape.circle)
                  : BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          rangeStartDecoration:
              darkMode
                  ? BoxDecoration(color: Colors.black, shape: BoxShape.circle)
                  : BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          rangeHighlightColor:
              darkMode
                  ? Color.fromARGB(255, 52, 168, 235)
                  : Color.fromARGB(255, 1, 105, 170),

          selectedDecoration: BoxDecoration(
            color: Color.fromARGB(255, 202, 33, 39),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
