import 'package:date_time_picker_widget/date_time_picker_widget.dart';

class Date {
  final int index;
  bool enabled;
  DateTime? date;
  final int weekIndex;
  bool isToday = false;
  final List<AvailableAppointments> availableAppointments;

  Date({
    required this.weekIndex,
    required this.index,
    required this.availableAppointments,
    this.enabled = true,
    this.date,
  }) {
    final now = DateTime.now();
    if (date != null) {
      isToday = date!.year == now.year &&
          date!.month == now.month &&
          date!.day == now.day;
    }
  }
}
