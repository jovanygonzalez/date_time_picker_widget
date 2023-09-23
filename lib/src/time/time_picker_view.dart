import 'package:date_time_picker_widget/src/date_time_picker_view_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:stacked/stacked.dart';

class TimePickerView extends ViewModelWidget<DateTimePickerViewModel> {
  const TimePickerView({Key? key}) : super(key: key);

  Text getEmptyText(DateTimePickerViewModel viewModel) {
    late final String text;

    final now = DateTime.now();
    if (viewModel.selectedDateObjet.date.year == now.year &&
        viewModel.selectedDateObjet.date.month == now.month &&
        viewModel.selectedDateObjet.date.day == now.day) {
      text = viewModel.todayTimeOutOfRangeError;
    } else {
      text = viewModel.timeOutOfRangeError;
    }

    return Text(text, style: const TextStyle(color: Colors.black87));
  }

  @override
  Widget build(BuildContext context, DateTimePickerViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
          child: Text(
            '${viewModel.timePickerTitle}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          height: 45,
          alignment: Alignment.center,
          child: viewModel.timeSlots.isEmpty
              ? getEmptyText(viewModel)
              : ScrollablePositionedList.builder(
                  itemScrollController: viewModel.timeScrollController,
                  itemPositionsListener: viewModel.timePositionsListener,
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.timeSlots.length,
                  itemBuilder: (context, index) {
                    final date = viewModel.timeSlots[index].startTime;
                    return InkWell(
                      onTap: () => viewModel.selectedTimeIndex = index,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: index == viewModel.selectedTimeIndex
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.grey,
                          ),
                          color: index == viewModel.selectedTimeIndex
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          // ignore: lines_longer_than_80_chars
                          '${DateFormat(viewModel.is24h ? 'HH:mm' : 'hh:mm aa').format(date)}',
                          style: TextStyle(
                              fontSize: 14,
                              color: index == viewModel.selectedTimeIndex
                                  ? Colors.white
                                  : Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
