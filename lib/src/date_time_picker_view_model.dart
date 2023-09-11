import 'package:date_time_picker_widget/src/date.dart';
import 'package:date_time_picker_widget/src/date_time_picker_type.dart';
import 'package:date_time_picker_widget/src/week.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:stacked/stacked.dart';
import 'date.dart' as personalized_date;

class DateTimePickerViewModel extends BaseViewModel {
  final DateTime? initialSelectedDate;
  final Function(DateTime date)? onDateChanged;
  final Function(DateTime time)? onTimeChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? startTime;
  final DateTime? endTime;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _startTime;
  DateTime? _endTime;
  Duration timeInterval;
  final List<String>? customStringWeekdays;
  final int numberOfWeeksToDisplay;
  final bool is24h;
  final DateTimePickerType type;
  final String timeOutOfRangeError;
  final String datePickerTitle;
  final String timePickerTitle;
  final String? locale;

  final List<Map<String, dynamic>> _weekdays = [
    {'value': DateTime.monday, 'text': 'L'},
    {'value': DateTime.tuesday, 'text': 'M'},
    {'value': DateTime.wednesday, 'text': 'M'},
    {'value': DateTime.thursday, 'text': 'J'},
    {'value': DateTime.friday, 'text': 'V'},
    {'value': DateTime.saturday, 'text': 'S'},
    {'value': DateTime.sunday, 'text': 'D'},
  ];

  List<Map<String, dynamic>> weekdays = [];

  DateTimePickerViewModel(
    this.initialSelectedDate,
    this.onDateChanged,
    this.onTimeChanged,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.timeInterval,
    // ignore: avoid_positional_boolean_parameters
    this.is24h,
    this.type,
    this.timeOutOfRangeError,
    this.datePickerTitle,
    this.timePickerTitle,
    this.customStringWeekdays,
    this.numberOfWeeksToDisplay,
    this.locale,
  ) {
    _startDate = startDate;
    _startTime = startTime;
    _endDate = endDate;
    _endTime = endTime;

    if (customStringWeekdays != null && customStringWeekdays!.length == 7) {
      weekdays = [
        {'value': DateTime.monday, 'text': customStringWeekdays![0]},
        {'value': DateTime.tuesday, 'text': customStringWeekdays![1]},
        {'value': DateTime.wednesday, 'text': customStringWeekdays![2]},
        {'value': DateTime.thursday, 'text': customStringWeekdays![3]},
        {'value': DateTime.friday, 'text': customStringWeekdays![4]},
        {'value': DateTime.saturday, 'text': customStringWeekdays![5]},
        {'value': DateTime.sunday, 'text': customStringWeekdays![6]},
      ];
    } else {
      weekdays = _weekdays;
    }
  }

  int? _selectedWeekday = 0;

  int? get selectedWeekday => _selectedWeekday;

  set selectedWeekday(int? selectedWeekday) {
    _selectedWeekday = selectedWeekday;
    notifyListeners();
  }

  int _numberOfWeeks = 0;

  int get numberOfWeeks => _numberOfWeeks;

  set numberOfWeeks(int numberOfWeeks) {
    _numberOfWeeks = numberOfWeeks;
    notifyListeners();
  }

  int _numberOfDays = 0;

  int get numberOfDays => _numberOfDays;

  set numberOfDays(int numberOfDays) {
    _numberOfDays = numberOfDays;
    notifyListeners();
  }

  DateTime? _selectedDate;

  DateTime? get selectedDate => _selectedDate;

  set selectedDate(DateTime? selectedDate) {
    _selectedDate = selectedDate;
    notifyListeners();
  }

  int _selectedDateIndex = 0;

  int get selectedDateIndex => _selectedDateIndex;

  set selectedDateIndex(int selectedDateIndex) {
    _selectedDateIndex = selectedDateIndex;
    notifyListeners();
    selectedDate = _findDate(selectedDateIndex);
    if (selectedDate != null) {
      selectedWeekday = selectedDate?.weekday;
      onDateChanged!(selectedDate!);
      _fetchTimeSlots(selectedDate);
    }
  }

  List<Week?>? _dateSlots = [];

  List<Week?>? get weekSlots => _dateSlots;

  set weekSlots(List<Week?>? dateSlots) {
    _dateSlots = dateSlots;
    notifyListeners();
  }

  int _selectedTimeIndex = 0;

  int get selectedTimeIndex => _selectedTimeIndex;

  set selectedTimeIndex(int selectedTimeIndex) {
    _selectedTimeIndex = selectedTimeIndex;
    notifyListeners();
    onTimeChanged!(timeSlots![selectedTimeIndex]);
  }

  List<DateTime>? _timeSlots = [];

  List<DateTime>? get timeSlots => _timeSlots;

  set timeSlots(List<DateTime>? timeSlots) {
    _timeSlots = timeSlots;
    notifyListeners();
  }

  final PageController _dateScrollController = PageController();

  PageController get dateScrollController => _dateScrollController;

  final ItemScrollController _timeScrollController = ItemScrollController();

  ItemScrollController get timeScrollController => _timeScrollController;

  final ItemPositionsListener _timePositionsListener =
      ItemPositionsListener.create();

  ItemPositionsListener get timePositionsListener => _timePositionsListener;

  final firstDayOnWeek = DateTime.monday;
  final lastDayOnWeek = DateTime.sunday;

  List<Date> newDatesList = [];

  void init() async {
    final currentDateTime = initialSelectedDate ?? DateTime.now().toUtc();
    final _currentDateTime = DateTime(
            currentDateTime.year, currentDateTime.month, currentDateTime.day)
        .toUtc();

    //DATE
    _startDate ??= _currentDateTime;
    _startDate =
        DateTime(_startDate!.year, _startDate!.month, _startDate!.day).toUtc();

    _endDate ??= _startDate!.add(const Duration(days: 365 * 5));
    _endDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day).toUtc();

    numberOfDays = _endDate!.difference(_startDate!).inDays;
    numberOfWeeks = Jiffy.parseFromDateTime(_endDate!)
        .diff(Jiffy.parseFromDateTime(_startDate!), unit: Unit.week)
        .toInt();

    int dateIndex = 0;

    final bool fillWeekBefore = _startDate!.weekday != firstDayOnWeek;
    final bool fillWeekAfter = endDate!.weekday != lastDayOnWeek;

    late final DateTime widgetStartDate;
    late final DateTime widgetEndDate;

    if (fillWeekBefore) {
      final int daysToFill = _startDate!.weekday - firstDayOnWeek;
      widgetStartDate = _startDate!.subtract(Duration(days: daysToFill));
    } else {
      widgetStartDate = _startDate!;
    }

    if (fillWeekAfter) {
      final int daysToFill = lastDayOnWeek - _endDate!.weekday;
      widgetEndDate = _endDate!.add(Duration(days: daysToFill));
    } else {
      widgetEndDate = _endDate!;
    }

    DateTime buildCurrentDate = widgetStartDate;
    int dayElementIndex = 0;

    int weekIndex = 0;
    Week fillingWeek = Week(index: weekIndex, days: []);

    while (buildCurrentDate.isBefore(widgetEndDate)) {
      if (buildCurrentDate.day == 29) {
        print("object");
      }

      //Todos los días lo agregamos en una semana
      final newDate = personalized_date.Date(
        weekIndex: weekIndex,
        index: dayElementIndex,
        date: buildCurrentDate,
        enabled: true,
      );
      fillingWeek.days.add(newDate);

      //Si el día es el último de la semana, agregamos la semana a la lista de semanas
      // y creamos una nueva semana
      if (buildCurrentDate.weekday == lastDayOnWeek) {
        weekSlots!.add(fillingWeek);
        fillingWeek = Week(index: weekIndex, days: []);
        weekIndex++;
      }

      buildCurrentDate = buildCurrentDate.add(const Duration(days: 1));
      dayElementIndex++;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (type == DateTimePickerType.Both || type == DateTimePickerType.Date) {
        if (weekSlots!.isNotEmpty) {
          selectedDateIndex = dateIndex;
          dateScrollController.animateToPage(
            0,
            duration: const Duration(seconds: 1),
            curve: Curves.linearToEaseOut,
          );
        } else {
          weekSlots = null;
        }
      }
    });

    if (type == DateTimePickerType.Time) {
      _fetchTimeSlots(currentDateTime);
    }
  }

  int _findWeekIndex(int dateIndex) {
    return dateIndex ~/ 7;
  }

  DateTime? _findDate(int dateIndex) {
    final weekIndex = dateIndex ~/ 7;

    if (weekSlots != null && weekSlots!.isNotEmpty) {
      final days = weekSlots![weekIndex]!.days;

      for (int i = 0; i < days.length; i++) {
        if (days[i].index == dateIndex) {
          return days[i].date;
        }
      }
    }

    return null;
  }

  void _fetchTimeSlots(DateTime? currentDateTime) {
    var _currentDateTime = currentDateTime;
    //TIME
    if (startTime == null) {
      _startTime = DateTime(
        _currentDateTime!.year,
        _currentDateTime.month,
        _currentDateTime.day,
      ).toUtc();
    }
    if (endTime == null) {
      _endTime = DateTime(
        _currentDateTime!.year,
        _currentDateTime.month,
        _currentDateTime.day,
        24,
      ).toUtc();
    }

    if (startTime != null || endTime != null) {
      // current time is not today
      if (_currentDateTime!.day - DateTime.now().toUtc().day > 0) {
        if (startTime != null) {
          _currentDateTime = _startTime = DateTime(
            _currentDateTime.year,
            _currentDateTime.month,
            _currentDateTime.day,
            startTime!.hour,
            startTime!.minute,
          ).toUtc();
        }
        if (endTime != null) {
          _endTime = DateTime(
            _currentDateTime.year,
            _currentDateTime.month,
            _currentDateTime.day,
            endTime!.hour,
            endTime!.minute,
          ).toUtc();
        }
      } else if (_currentDateTime
          .isBefore(DateTime.now().toUtc().add(const Duration(seconds: 5)))) {
        // current time is today
        _currentDateTime = _startTime = DateTime(
          _currentDateTime.year,
          _currentDateTime.month,
          _currentDateTime.day,
          DateTime.now().toUtc().hour,
          DateTime.now().toUtc().minute,
        ).toUtc();

        if (startTime != null && _currentDateTime.hour < startTime!.hour) {
          _currentDateTime = _startTime = DateTime(
            _currentDateTime.year,
            _currentDateTime.month,
            _currentDateTime.day,
            startTime!.hour,
            startTime!.minute,
          ).toUtc();
        }

        if (endTime != null) {
          _endTime = DateTime(
            _currentDateTime.year,
            _currentDateTime.month,
            _currentDateTime.day,
            endTime!.hour,
            endTime!.minute,
          ).toUtc();
        } else {
          _endTime = DateTime(
            _currentDateTime.year,
            _currentDateTime.month,
            _currentDateTime.day,
            24,
            0,
          ).toUtc();
        }
      }
    }

    int timeIndex = -1;
    timeSlots = [];
    for (int i = 0; i < _getTimeSlotsCount(); i++) {
      final time = _getNextTime(i);
      timeSlots!.add(time);
      if (timeIndex == -1 &&
          (time.difference(_currentDateTime!).inMinutes <=
                  timeInterval.inMinutes ||
              time.difference(_currentDateTime).inMinutes <= 0)) {
        timeIndex = i;
      }
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (type == DateTimePickerType.Both || type == DateTimePickerType.Time) {
        if (timeSlots!.isNotEmpty) {
          selectedTimeIndex = timeIndex == -1 ? 0 : timeIndex;
          timeScrollController.scrollTo(
              index: selectedTimeIndex, duration: const Duration(seconds: 1));
        } else {
          timeSlots = null;
        }
      }
    });
  }

  int _getTimeSlotsCount() {
    return (_endTime!.difference(_startTime!).inMinutes ~/
            timeInterval.inMinutes)
        .toInt();
  }

  DateTime _getNextTime(int index) {
    final dt = _startTime!.add(
        Duration(minutes: (60 - _startTime!.minute) % timeInterval.inMinutes));
    return dt.add(Duration(minutes: timeInterval.inMinutes * index));
  }

  DateTime getNextDate(int index) {
    return _startDate!.add(Duration(days: index));
  }

  void onClickNext() {
    final dt = Jiffy.parseFromDateTime(selectedDate!).add(months: 1);
    final diff = dt
        .diff(
          Jiffy.parseFromDateTime(selectedDate!),
          unit: Unit.day,
        )
        .toInt();

    if (numberOfDays < selectedDateIndex + diff) {
      selectedDateIndex = numberOfDays - 1;
    } else {
      selectedDateIndex += diff;
    }

    dateScrollController.animateToPage(_findWeekIndex(selectedDateIndex),
        duration: const Duration(seconds: 1), curve: Curves.linearToEaseOut);
  }

  void onClickPrevious() {
    final dt = Jiffy.parseFromDateTime(selectedDate!).subtract(months: 1);
    final diff =
        Jiffy.parseFromDateTime(selectedDate!).diff(dt, unit: Unit.day).toInt();

    if (selectedDateIndex < diff) {
      selectedDateIndex = 0;
    } else {
      selectedDateIndex -= diff;
    }

    dateScrollController.animateToPage(_findWeekIndex(selectedDateIndex),
        duration: const Duration(seconds: 1), curve: Curves.linearToEaseOut);
  }
}
