class Date {
  final int index;
  bool enabled;
  DateTime? date;
  final int weekIndex;
  bool isToday = false;

  Date(
      {required this.weekIndex,
      required this.index,
      this.enabled = true,
      this.date}) {
    final now = DateTime.now();
    if (date != null) {
      isToday = date!.year == now.year &&
          date!.month == now.month &&
          date!.day == now.day;
    }
  }
}
