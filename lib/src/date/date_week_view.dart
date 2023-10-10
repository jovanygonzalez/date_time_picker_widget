import 'package:date_time_picker_widget/src/date_time_picker_view_model.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../date.dart';
import '../week.dart';

class DateWeekView extends ViewModelWidget<DateTimePickerViewModel> {
  final BoxConstraints constraints;

  const DateWeekView(this.constraints);

  @override
  Widget build(BuildContext context, DateTimePickerViewModel viewModel) {
    var w = ((constraints.biggest.width - 20) - (32 * 7)) / 7;
    w = (w + w / 7).roundToDouble() + 0.3;
    return Container(
      height: 53.0 * viewModel.numberOfWeeksToDisplay,
      child: PageView.builder(
        controller: viewModel.dateScrollController,
        itemCount: ((viewModel.weekSlots?.length ?? 0) /
                viewModel.numberOfWeeksToDisplay)
            .round(),
        itemBuilder: (context, pageIndex) {
          return ListView.builder(
            itemCount: viewModel.numberOfWeeksToDisplay,
            itemBuilder: (context, wIndex) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 53,
                child: ListView.separated(
                  separatorBuilder: (context, index) {
                    return SizedBox(width: w);
                  },
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  itemBuilder: (context, i) {
                    final Week week = viewModel.weekSlots![pageIndex]!;
                    final Date date = week.days[i];

                    return Center(
                      child: InkWell(
                        //El día de hoy sí es seleccionable
                        //Pero con ciertos aspectos especiales
                        onTap: date.enabled || date.isToday
                            ? () => viewModel.selectedDateObjet = date
                            : null,
                        child: Container(
                          decoration: getCircleBoxDecoration(
                              date, viewModel.selectedDateObjet.index, context),
                          alignment: Alignment.center,
                          width: 32,
                          height: 32,
                          child: Text(
                            '${date.date.day}',
                            style: getCircleTextStyle2(
                                date, viewModel.selectedDateObjet.index),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  BoxDecoration getCircleBoxDecoration(
      Date date, int selectedIndex, BuildContext context) {
    //Establecer el color del borde del circulo
    late final Color colorBorder;

    if (date.index == selectedIndex || date.isToday) {
      //Si el día está seleccionado o es hoy se pinta del color secundario
      colorBorder = Theme.of(context).colorScheme.primary;
    } else {
      //Si el día no está seleccionado ni es hoy se pinta de gris
      colorBorder = Colors.grey;
    }

    //Establecer el color del fondo del circulo
    late final Color colorBackground;

    if (date.enabled) {
      if (date.index == selectedIndex) {
        colorBackground = Theme.of(context).colorScheme.primary;
      } else {
        colorBackground = Colors.white;
      }
    } else {
      colorBackground = Colors.grey.shade300;
    }

    //Establecer el círculo
    return BoxDecoration(
      borderRadius: BorderRadius.circular(90),
      border: Border.all(
        color: colorBorder,
        // width: 1.5
      ),
      color: colorBackground,
    );
  }

  TextStyle getCircleTextStyle2(Date date, int selectedIndex) {
    late final Color colorText;

    if (date.index == selectedIndex) {
      colorText = Colors.white;
    } else {
      colorText = Colors.grey;
    }

    return TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: colorText);
  }
}
