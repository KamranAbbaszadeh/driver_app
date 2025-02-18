import 'package:driver_app/front/tools/ride_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

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
  @override
  void initState() {
    super.initState();
    selectedDate = widget.ride.startDate.toDate();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final ride = widget.ride;
    return Container(
      height: height * 0.12,
      padding: EdgeInsets.symmetric(vertical: height * 0.02),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(width * 0.076),
          topRight: Radius.circular(width * 0.076),
        ),
      ),
      child: TableCalendar(
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

        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            selectedDate = selectedDay;
            widget.updateSelectedDay(selectedDay);
          });
        },

        headerVisible: false,
        selectedDayPredicate: (day) {
          return isSameDay(selectedDate, day);
        },
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
          weekendStyle: GoogleFonts.ptSans(fontWeight: FontWeight.w600),
        ),
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
