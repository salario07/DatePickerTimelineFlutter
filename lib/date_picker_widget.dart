import 'package:date_picker_timeline/date_widget.dart';
import 'package:date_picker_timeline/extra/color.dart';
import 'package:date_picker_timeline/extra/style.dart';
import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:date_picker_timeline/typedefs.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

class DatePicker extends StatefulWidget {
  /// Start Date in case user wants to show past dates
  /// If not provided calendar will start from the initialSelectedDate
  final DateTime startDate;

  /// Width of the selector
  final double width;

  /// Height of the selector
  final double height;

  /// DatePicker Controller
  final DatePickerController? controller;

  /// Text color for the selected Date
  final Color selectedTextColor;

  /// Background color for the selector
  final Color selectionColor;

  /// Text Color for the deactivated dates
  final Color deactivatedColor;

  /// TextStyle for Month Value
  final TextStyle monthTextStyle;

  /// TextStyle for day Value
  final TextStyle dayTextStyle;

  /// TextStyle for the date Value
  final TextStyle dateTextStyle;

  /// Current Selected Date
  final DateTime? /*?*/ initialSelectedDate;

  /// Contains the list of inactive dates.
  /// All the dates defined in this List will be deactivated
  final List<DateTime>? inactiveDates;

  /// Contains the list of active dates.
  /// Only the dates in this list will be activated.
  final List<DateTime>? activeDates;

  /// Callback function for when a different date is selected
  final DateChangeListener? onDateChange;

  /// Max limit up to which the dates are shown.
  /// Days are counted from the startDate
  final int daysCount;

  /// Locale for the calendar default: en_us
  final String locale;

  final List<BoxShadow>? selectionBoxShadows;

  final EdgeInsetsGeometry? itemPadding;
  final EdgeInsetsGeometry? Function(int index)? itemMargin;
  final EdgeInsetsGeometry? listViewPadding;
  final double? borderRadius;

  final DateTileBuilder? tileBuilder;
  final double spacing;

  DatePicker(
    this.startDate, {
    Key? key,
    this.width = 60,
    this.height = 80,
    this.controller,
    this.monthTextStyle = defaultMonthTextStyle,
    this.dayTextStyle = defaultDayTextStyle,
    this.dateTextStyle = defaultDateTextStyle,
    this.selectedTextColor = Colors.white,
    this.selectionColor = AppColors.defaultSelectionColor,
    this.deactivatedColor = AppColors.defaultDeactivatedColor,
    this.initialSelectedDate,
    this.activeDates,
    this.inactiveDates,
    this.daysCount = 500,
    this.onDateChange,
    this.itemPadding,
    this.itemMargin,
    this.listViewPadding,
    this.tileBuilder,
    this.borderRadius,
    this.selectionBoxShadows,
    this.spacing = 0,
    this.locale = "en_US",
  }) : assert(
            activeDates == null || inactiveDates == null,
            "Can't "
            "provide both activated and deactivated dates List at the same time.");

  @override
  State<StatefulWidget> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? _currentDate;

  ScrollController _controller = ScrollController();

  late final TextStyle selectedDateStyle;
  late final TextStyle selectedMonthStyle;
  late final TextStyle selectedDayStyle;

  late final TextStyle deactivatedDateStyle;
  late final TextStyle deactivatedMonthStyle;
  late final TextStyle deactivatedDayStyle;

  @override
  void initState() {
    // Init the calendar locale
    initializeDateFormatting(widget.locale, null);
    // Set initial Values
    _currentDate = widget.initialSelectedDate;

    if (widget.controller != null) {
      widget.controller!.setDatePickerState(this);
    }

    this.selectedDateStyle =
        widget.dateTextStyle.copyWith(color: widget.selectedTextColor);
    this.selectedMonthStyle =
        widget.monthTextStyle.copyWith(color: widget.selectedTextColor);
    this.selectedDayStyle =
        widget.dayTextStyle.copyWith(color: widget.selectedTextColor);

    this.deactivatedDateStyle =
        widget.dateTextStyle.copyWith(color: widget.deactivatedColor);
    this.deactivatedMonthStyle =
        widget.monthTextStyle.copyWith(color: widget.deactivatedColor);
    this.deactivatedDayStyle =
        widget.dayTextStyle.copyWith(color: widget.deactivatedColor);

    super.initState();
  }

  @override
  void didUpdateWidget(final DatePicker oldWidget) {
    if (!DateUtils.isSameDay(
        oldWidget.initialSelectedDate, widget.initialSelectedDate)) {
      _currentDate = widget.initialSelectedDate;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => Container(
        height: widget.height,
        child: ListView.separated(
          padding: widget.listViewPadding,
          itemCount: widget.daysCount,
          scrollDirection: Axis.horizontal,
          controller: _controller,
          separatorBuilder: (context, index) => SizedBox(
            width: widget.spacing,
          ),
          itemBuilder: (context, index) {
            // get the date object based on the index position
            // if widget.startDate is null then use the initialDateValue
            DateTime date;

            final int day = widget.startDate.day;
            final DateTime _date = widget.startDate.copyWith(day: day + index);
            date = DateTime(_date.year, _date.month, _date.day, 0, 0, 0, 0, 0);
            bool isDeactivated = false;

            // check if this date needs to be deactivated for only DeactivatedDates
            if (widget.inactiveDates != null) {
//            print("Inside Inactive dates.");
              for (DateTime inactiveDate in widget.inactiveDates!) {
                if (_compareDate(date, inactiveDate)) {
                  isDeactivated = true;
                  break;
                }
              }
            }

            // check if this date needs to be deactivated for only ActivatedDates
            if (widget.activeDates != null) {
              isDeactivated = true;
              for (DateTime activateDate in widget.activeDates!) {
                // Compare the date if it is in the
                if (_compareDate(date, activateDate)) {
                  isDeactivated = false;
                  break;
                }
              }
            }

            // Check if this date is the one that is currently selected
            final bool isSelected = _currentDate != null
                ? _compareDate(date, _currentDate!)
                : false;

            if (widget.tileBuilder != null) {
              return InkWell(
                onTap: () => _onDateSelected(
                  date,
                  isDeactivated,
                ),
                borderRadius: widget.borderRadius != null
                    ? BorderRadius.all(
                        Radius.circular(
                          widget.borderRadius!,
                        ),
                      )
                    : null,
                child: widget.tileBuilder!.call(
                  date,
                  isSelected,
                  isDeactivated,
                ),
              );
            }

            // Return the Date Widget
            return DateWidget(
              date: date,
              monthTextStyle: isDeactivated
                  ? deactivatedMonthStyle
                  : isSelected
                      ? selectedMonthStyle
                      : widget.monthTextStyle,
              dateTextStyle: isDeactivated
                  ? deactivatedDateStyle
                  : isSelected
                      ? selectedDateStyle
                      : widget.dateTextStyle,
              dayTextStyle: isDeactivated
                  ? deactivatedDayStyle
                  : isSelected
                      ? selectedDayStyle
                      : widget.dayTextStyle,
              width: widget.width,
              locale: widget.locale,
              selectionColor:
                  isSelected ? widget.selectionColor : Colors.transparent,
              itemPadding: widget.itemPadding,
              itemMargin: widget.itemMargin?.call(index),
              borderRadius: widget.borderRadius,
              selectionBoxShadows:
                  isSelected ? widget.selectionBoxShadows : null,
              onDateSelected: (selectedDate) => _onDateSelected(
                selectedDate,
                isDeactivated,
              ),
            );
          },
        ),
      );

  /// Helper function to compare two dates
  /// Returns True if both dates are the same
  bool _compareDate(DateTime date1, DateTime date2) =>
      date1.day == date2.day &&
      date1.month == date2.month &&
      date1.year == date2.year;

  void _onDateSelected(
    final DateTime selectedDate,
    bool isDeactivated,
  ) {
    // Don't notify listener if date is deactivated
    if (isDeactivated) return;

    // A date is selected
    if (widget.onDateChange != null) {
      widget.onDateChange!(selectedDate);
    }
    setState(() {
      _currentDate = selectedDate;
    });
  }
}

class DatePickerController {
  _DatePickerState? _datePickerState;

  void setDatePickerState(_DatePickerState state) {
    _datePickerState = state;
  }

  void jumpToSelection() {
    assert(_datePickerState != null,
        'DatePickerController is not attached to any DatePicker View.');

    // jump to the current Date
    _datePickerState!._controller
        .jumpTo(_calculateDateOffset(_datePickerState!._currentDate!));
  }

  /// This function will animate the Timeline to the currently selected Date
  void animateToSelection(
      {duration = const Duration(milliseconds: 500), curve = Curves.linear}) {
    assert(_datePickerState != null,
        'DatePickerController is not attached to any DatePicker View.');

    // animate to the current date
    _datePickerState!._controller.animateTo(
        _calculateDateOffset(_datePickerState!._currentDate!),
        duration: duration,
        curve: curve);
  }

  /// This function will animate to any date that is passed as an argument
  /// In case a date is out of range nothing will happen
  void animateToDate(DateTime date,
      {duration = const Duration(milliseconds: 500), curve = Curves.linear}) {
    assert(_datePickerState != null,
        'DatePickerController is not attached to any DatePicker View.');

    _datePickerState!._controller.animateTo(_calculateDateOffset(date),
        duration: duration, curve: curve);
  }

  /// This function will animate to any date that is passed as an argument
  /// this will also set that date as the current selected date
  void setDateAndAnimate(DateTime date,
      {duration = const Duration(milliseconds: 500), curve = Curves.linear}) {
    assert(_datePickerState != null,
        'DatePickerController is not attached to any DatePicker View.');

    _datePickerState!._controller.animateTo(_calculateDateOffset(date),
        duration: duration, curve: curve);

    if (date.compareTo(_datePickerState!.widget.startDate) >= 0 &&
        date.compareTo(_datePickerState!.widget.startDate
                .add(Duration(days: _datePickerState!.widget.daysCount))) <=
            0) {
      // date is in the range
      _datePickerState!._currentDate = date;
    }
  }

  /// Calculate the number of pixels that needs to be scrolled to go to the
  /// date provided in the argument
  double _calculateDateOffset(DateTime date) {
    final startDate = DateTime(
        _datePickerState!.widget.startDate.year,
        _datePickerState!.widget.startDate.month,
        _datePickerState!.widget.startDate.day);

    final int offset = date.difference(startDate).inDays;
    return (offset * (_datePickerState!.widget.width)) + (offset * 6);
  }
}
