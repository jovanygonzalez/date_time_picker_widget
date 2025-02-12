import 'package:date_time_picker_widget/src/appointments/available_appointments.dart';
import 'package:date_time_picker_widget/src/date.dart';
import 'package:date_time_picker_widget/src/date_time_picker_type.dart';
import 'package:date_time_picker_widget/src/week.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:stacked/stacked.dart';
import 'date.dart' as personalized_date;

class DateTimePickerViewModel extends BaseViewModel {
  final DateTime? initialSelectedDate;
  final Function(DateTime date)? onDateChanged;
  final Function(AvailableAppointments time)? onTimeChanged;
  DateTime? startDate;
  DateTime? endDate;
  Duration timeInterval;
  final List<String>? customStringWeekdays;
  final int numberOfWeeksToDisplay;
  final bool is24h;
  final DateTimePickerType type;
  final String timeOutOfRangeError;
  final String todayTimeOutOfRangeError;
  final String datePickerTitle;
  final String timePickerTitle;
  final String? locale;

  //Se espera que el mapa tenga formato de año-mes-día, ejemplo:
  //{"2021-12-02": [{"start": "2021-12-02 08:00:00", "end": "2021-12-02 09:00:00"}]}
  final Map<String, List<AvailableAppointments>> allDaysInfo;

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
    this.timeInterval,
    // ignore: avoid_positional_boolean_parameters
    this.is24h,
    this.type,
    this.timeOutOfRangeError,
    this.todayTimeOutOfRangeError,
    this.datePickerTitle,
    this.timePickerTitle,
    this.customStringWeekdays,
    this.numberOfWeeksToDisplay,
    this.locale,
    this.allDaysInfo,
  ) {
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

  late Date _selectedDateObjet;
  Date get selectedDateObjet {
    return _selectedDateObjet;
  }

  set selectedDateObjet(Date selectedDateObjet) {
    _selectedDateObjet = selectedDateObjet;
    notifyListeners();
    onDateChanged!(selectedDateObjet.date);

    //Si no es ninguno de los dos, no se hace nada
    if (type == DateTimePickerType.Both || type == DateTimePickerType.Time) {
      _fetchTimeSlots(selectedDateObjet);
    }
  }

  List<Week?>? _dateSlots = [];
  List<Week?>? get weekSlots => _dateSlots;
  set weekSlots(List<Week?>? dateSlots) {
    _dateSlots = dateSlots;
    notifyListeners();
  }

  int initialSelectedTimeIndex = 0;
  int _selectedTimeIndex = 0;
  int get selectedTimeIndex => _selectedTimeIndex;
  set selectedTimeIndex(int selectedTimeIndex) {
    _selectedTimeIndex = selectedTimeIndex;
    notifyListeners();
    onTimeChanged!(timeSlots[selectedTimeIndex]);
  }

  List<AvailableAppointments> _timeSlots = [];
  List<AvailableAppointments> get timeSlots => _timeSlots;
  set timeSlots(List<AvailableAppointments> timeSlots) {
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

  void init() {
    //TODO: CORREGIR LA DIFERENCIA ENTRE UTC Y LOCAL YA QUE GENERA ERRORES
    //2023-09-22 18:25:27.840328
    //2023-09-23 00:26:22.242856Z
    final now = DateTime.now().toUtc();

    final currentDateTime = initialSelectedDate ?? now;

    //DATE
    //Star Date será now a menos que el usuario haya indicado una fecha inicial
    startDate ??= DateTime(now.year, now.month, now.day).toUtc();
    //Ya sea que el usuario haya indicado una fecha inicial o no
    //Se debe truncar a ceros los minutos y segundos
    startDate =
        DateTime(startDate!.year, startDate!.month, startDate!.day).toUtc();

    endDate ??= startDate!.add(const Duration(days: 365 * 5));
    endDate = DateTime(endDate!.year, endDate!.month, endDate!.day).toUtc();

    numberOfDays = endDate!.difference(startDate!).inDays;
    numberOfWeeks = Jiffy.parseFromDateTime(endDate!)
        .diff(Jiffy.parseFromDateTime(startDate!), unit: Unit.week)
        .toInt();

    _selectedDateObjet = fillWeekSlots(currentDateTime);
    initialSelectedTimeIndex = findInitialSelectedTimeIndex(
        _selectedDateObjet.availableAppointments, currentDateTime);

    Future.delayed(const Duration(milliseconds: 500), () {
      //Una vez que termines de "construir" el weekSlots en fillWeekSlots() vamos a establecer el día seleccionado aprovechando el delayed
      selectedDateObjet = _selectedDateObjet;

      if (type == DateTimePickerType.Both || type == DateTimePickerType.Date) {
        if (weekSlots!.isNotEmpty) {
          dateScrollController.animateToPage(
            selectedDateObjet.weekIndex,
            duration: const Duration(seconds: 1),
            curve: Curves.linearToEaseOut,
          );
        } else {
          weekSlots = null;
        }
      }
    });

    if (type == DateTimePickerType.Time) {
      _fetchTimeSlots(selectedDateObjet);
    }
  }

  /*
  * Recupera el lunes anterior a partir de la fecha inicial
  * O en caso de que la fecha inicial sea lunes, entonces regresa la misma fecha inicial
   */
  DateTime getWidgetStartDate(DateTime initialSelectedDate) {
    if (initialSelectedDate.weekday == DateTime.monday) {
      return initialSelectedDate;
    } else {
      final int daysToPreviousMonday =
          initialSelectedDate.weekday - DateTime.monday;
      return initialSelectedDate.subtract(Duration(days: daysToPreviousMonday));
    }
  }

  /*
  * Recupera el siguiente domingo a partir de la fecha final
  * O en caso de que la fecha final sea domingo, entonces regresa la misma fecha final
  * */
  DateTime getWidgetEndDate(DateTime initialSelectedDate) {
    if (initialSelectedDate.weekday == DateTime.sunday) {
      return initialSelectedDate;
    } else {
      final int daysToNextSunday =
          DateTime.sunday - initialSelectedDate.weekday;
      return initialSelectedDate.add(Duration(days: daysToNextSunday));
    }
  }

  /*
  * Llena la lista de semanas con los días que se van a mostrar en el widget
  * En el widget algunas veces se deben mostrar días que no están en el rango indicado,
  * por ello se debe calcular si sí o no (fillWeekBefore & fillWeekAfter).
  *
  * Una vez obtenido el rango de días que se van a mostrar (widgetStartDate & widgetEndDate),
  * Realizaremos un avance dia tras día hasta llegar al final del rango.
  *
  * Si el día actual es el último de la semana (domingo), agregamos la semana a la lista de semanas (weekSlots)
  * */
  Date fillWeekSlots(DateTime initialSelectedDate) {
    late Date initialSelectedDateObjet;

    int dayElementIndex = 0;
    int weekIndex = 0;
    Week fillingWeek = Week(index: weekIndex, days: []);

    final DateTime widgetStartDate = getWidgetStartDate(startDate!);
    final DateTime widgetEndDate = getWidgetEndDate(endDate!);

    DateTime buildCurrentDate = widgetStartDate;

    while (buildCurrentDate.isBefore(widgetEndDate)) {
      //Todos los días lo agregamos en una semana

      late final List<AvailableAppointments> availableAppointments;

      final buildCurrentDateStr =
          DateFormat('yyyy-MM-dd').format(buildCurrentDate);
      if (allDaysInfo.containsKey(buildCurrentDateStr)) {
        availableAppointments = allDaysInfo[buildCurrentDateStr]!;
      } else {
        availableAppointments = [];
      }

      final newDate = personalized_date.Date(
        weekIndex: weekIndex,
        index: dayElementIndex,
        date: buildCurrentDate,
        enabled: getIsEnabledDay(buildCurrentDate, availableAppointments),
        availableAppointments: availableAppointments,
      );

      fillingWeek.days.add(newDate);

      //Si el día es el último de la semana, agregamos la semana a la lista de semanas
      // y creamos una nueva semana
      if (buildCurrentDate.weekday == DateTime.sunday) {
        //Finalizó la semana y se agrega a la lista de semanas
        weekSlots!.add(fillingWeek);

        //El nuevo weekIndex se le aumentará 1.
        weekIndex++;
        fillingWeek = Week(index: weekIndex, days: []);
      }

      //Aprovechamos la iteración para obtener el objeto Date del día seleccionado inicial
      if (areDatesEqual(buildCurrentDate, initialSelectedDate)) {
        initialSelectedDateObjet = newDate;
      }

      buildCurrentDate = buildCurrentDate.add(const Duration(days: 1));
      dayElementIndex++;
    }

    return initialSelectedDateObjet;
  }

  int findInitialSelectedTimeIndex(
      List<AvailableAppointments> availableAppointments,
      DateTime initialSelectedDate) {
    if (availableAppointments.isEmpty) {
      return 0;
    } else {
      for (var i = 0; i < availableAppointments.length; i++) {
        final startTime = availableAppointments[i].startTime;
        if (startTime.hour == initialSelectedDate.hour &&
            startTime.minute == initialSelectedDate.minute) {
          return i;
        }
      }
      return 0;
    }
  }

  bool areDatesEqual(DateTime date1, DateTime date2) {
    return date1.day == date2.day &&
        date1.month == date2.month &&
        date1.year == date2.year;
  }

  /*
  * Obtiene el estado de un día, si está habilitado o no
  * Solo es verdadero si está dentro del rango de fechas proporcionado
  */
  bool getIsEnabledDay(
      DateTime date, List<AvailableAppointments> appointments) {
    bool isEnabled = true;

    if (date.isBefore(startDate!) ||
        date.isAfter(endDate!) ||
        appointments.isEmpty) {
      //Si es antes del día inicial o después del día final
      //Si no hay citas disponibles
      isEnabled = false;
    }

    return isEnabled;
  }

  void _fetchTimeSlots(Date currentDate) {
    timeSlots = currentDate.availableAppointments;
    if (timeSlots.isNotEmpty) {
      //Si el día actual tiene citas disponibles, entonces se debe seleccionar la primera
      Future.delayed(const Duration(milliseconds: 500), () {
        //Este if permite que solo una vez se seleccione lo que se haya seleccionado previamente
        //Ya que si no se hace, cada vez que se cambie de día se seleccionará lo que se haya seleccionado previamente
        if (initialSelectedTimeIndex > 0) {
          //Si hay una cita seleccionada previamente entonces se selecciona esa
          selectedTimeIndex = initialSelectedTimeIndex;
          //Se reinicia el valor para que se pierda lo que se haya seleccionado previamente
          initialSelectedTimeIndex = 0;
        } else {
          selectedTimeIndex = 0;
        }

        timeScrollController.scrollTo(
            index: selectedTimeIndex, duration: const Duration(seconds: 1));
      });
    }
  }

  //TODO: Esto no es funcional si el mes completo está deshabilitado.
  //La probabilidad es poca pero se debe corregir con en el futuro
  void onClickPrevious() {
    Date? latMonthPreviousDate;
    Date? lastMonthDate;
    final int targetMonth = getPreviouMonth(selectedDateObjet.date.month);

    /*
    Este for puede ser un poco complejo de enteder.
    Pero lo que hace es ir en decremento, ambos for (decrementa la lista de semanas y los días de la semana )
    Tener en cuenta que hay dos variables latMonthPreviousDate y lastMonthDate:
    1. El objetivo de latMonthPreviousDate es guardar el último día del mes anterior
    2. Y el objetivo de lastMonthDate es guardar el último día del mes (sin importar si es el mes anterior)

    Cuando lastMonthDate resulta tener un mes del que no se busca entonces latMonthPreviousDate ya debería tener el último día del mes anterior
    * */
    for (var i = selectedDateObjet.weekIndex; i >= 0; i--) {
      final Week week = weekSlots![i]!;

      for (var j = week.days.length - 1; j >= 0; j--) {
        final Date date = week.days[j];
        lastMonthDate = date;
        if (date.enabled && date.date.month == targetMonth) {
          latMonthPreviousDate = lastMonthDate;
        }
      }

      //Cuando lastMonthDate apenas resulta tener el mes anterior anterior (anterior por dos)
      // latMonthPreviousDate ya debería tener el último día del mes anterior (anterior por uno)
      if (lastMonthDate!.date.month == getPreviouMonth(targetMonth)) {
        break;
      }
    }

    if (latMonthPreviousDate != null) {
      setNewDate(latMonthPreviousDate);
    }
  }

  //TODO: Esto no es funcional si el mes completo está deshabilitado.
  //La probabilidad es poca pero se debe corregir con en el futuro
  //Lo que hace esta función es iterar desde el día seleccionado hasta el final de la lista de semanas
  //Hasta que encuentre un día habilitado que sea del siguiente mes
  void onClickNext() {
    Date? firstMonthDate;
    final int targetMonth = getNextMonth(selectedDateObjet.date.month);

    outerLoop:
    for (var i = selectedDateObjet.weekIndex; i < weekSlots!.length; i++) {
      final Week week = weekSlots![i]!;

      for (var j = 0; j < week.days.length; j++) {
        final Date date = week.days[j];
        if (date.enabled && date.date.month == targetMonth) {
          firstMonthDate = date;
          break outerLoop;
        }
      }
    }

    if (firstMonthDate != null) {
      setNewDate(firstMonthDate);
    }
  }

  void setNewDate(Date date) {
    selectedDateObjet = date;

    dateScrollController.animateToPage(date.weekIndex,
        duration: const Duration(seconds: 1), curve: Curves.linearToEaseOut);
  }

  int getNextMonth(int month) {
    if (month == DateTime.december) {
      return DateTime.january;
    } else {
      return month + 1;
    }
  }

  int getPreviouMonth(int month) {
    if (month == DateTime.january) {
      return DateTime.december;
    } else {
      return month - 1;
    }
  }
}
