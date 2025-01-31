import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/text_field.dart';

extension EVEditor<T> on EV<T> {}

extension AxisSizeEditor on AxisSize {
  Widget getEditor(String title) {
    final TextEditingController valueController =
        TextEditingController(text: value != null ? value!.toString() : "");
    final TextEditingController minController = TextEditingController(
        text: minPixels != null ? minPixels!.toString() : "");
    final TextEditingController maxController = TextEditingController(
        text: maxPixels != null ? maxPixels!.toString() : "");
    final TextEditingController flexController =
        TextEditingController(text: flex != null ? flex!.toString() : "");

    return ChangeListener(
      source: this,
      builder: () {
        debugPrint("Building AxisSizeEditor for $title: $value");
        if (valueController.text != value.toString()) {
          valueController.text = value.toString();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$title:"),
            Row(
              children: [
                Expanded(
                  child: MyNumberField<double>(
                      controller: valueController,
                      hintText: "$title in pixels",
                      onChanged: (value) => fixed(value)),
                ),
                Gap.w8,
                //MyIconButtons for auto, expand, fixed
                FloatingBar(
                  decoration: FloatingBarDecoration.flatLightMode,
                  children: [
                    MyIconButton(
                        icon: Icons.compress,
                        tooltip: "Auto",
                        size: 14,
                        isSelected: type == SizeType.auto,
                        decoration: MyIconButtonDecoration.onDarkBar,
                        primaryAction: (_) {
                          auto();
                        }),
                    MyIconButton(
                        icon: Icons.expand,
                        tooltip: "Expand",
                        size: 14,
                        isSelected: type == SizeType.expand,
                        decoration: MyIconButtonDecoration.onDarkBar,
                        primaryAction: (_) {
                          expand();
                        }),
                    MyIconButton(
                      icon: Icons.lock,
                      tooltip: "Fixed",
                      size: 14,
                      isSelected: type == SizeType.fixed,
                      decoration: MyIconButtonDecoration.onDarkBar,
                      primaryAction: (_) {
                        if (value != null) {
                          fixed(value!);
                        } else {
                          debugPrint("Value is null");
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            //Min, max and if expand, flex
            if (type != SizeType.fixed) ...[
              Gap.h8,
              Row(
                children: [
                  Expanded(
                    child: MyNumberField<double>(
                      controller: minController,
                      hintText: "Min",
                      onChanged: (value) {
                        minPixels = value;
                      },
                    ),
                  ),
                  Gap.w4,
                  Expanded(
                    child: MyNumberField<double>(
                      controller: maxController,
                      hintText: "Max",
                      onChanged: (value) {
                        maxPixels = value;
                      },
                    ),
                  ),
                  if (type == SizeType.expand) ...[
                    Gap.w4,
                    Expanded(
                      child: MyNumberField<int>(
                        controller: flexController,
                        hintText: "Flex",
                        onChanged: (value) {
                          flex = value;
                        },
                      ),
                    ),
                  ]
                ],
              ),
            ]
          ],
        );
      },
    );
  }
}
