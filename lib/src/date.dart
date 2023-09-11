class Date {
  final int index;
  bool enabled;
  DateTime? date;
  final int weekIndex;

  Date(
      {required this.weekIndex,
      required this.index,
      this.enabled = true,
      this.date});
}
