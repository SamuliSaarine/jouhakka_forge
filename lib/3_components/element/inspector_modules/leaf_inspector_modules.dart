import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/element/inspector_modules/a_inspector_modules.dart';
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/text_field.dart';
import 'package:jouhakka_forge/5_style/icons/lucide_map.dart';

extension TextElementEditor on TextElement {
  Widget getEditor() {
    final TextEditingController textController =
        TextEditingController(text: text.value);
    final TextEditingController fontSizeController =
        TextEditingController(text: fontSize.toString());

    return ChangeListener(
      source: this,
      builder: () {
        return Column(
          children: [
            MyTextField(
              controller: textController,
              onSubmitted: (value) {
                try {
                  text = VariableParser.parse<String>(value, root,
                      notifyListeners: notifyListeners);
                  return true;
                } catch (e) {
                  return false;
                }
              },
            ),
            Gap.h8,
            MyTextField(
              controller: fontSizeController,
              onSubmitted: (value) {
                try {
                  fontSize = VariableParser.parse<double>(value, root,
                      notifyListeners: notifyListeners);
                  return true;
                } catch (e) {
                  return false;
                }
              },
            ),
            alignment.getEditor((alignment) {
              this.alignment = alignment;
            }),
          ],
        );
      },
    );
  }
}

extension IconElementEditor on IconElement {
  Widget getEditor() {
    return ChangeListener(
      source: this,
      builder: () {
        return SizedBox(
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6, // Adjust this to fit your layout needs
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: lucideMap.length,
            itemBuilder: (context, index) {
              (String, int) item = lucideMap[index];
              IconData iconData = IconData(
                item.$2,
                fontFamily: 'Lucide',
                fontPackage: 'lucide_icons_flutter',
              );
              return MyIconButton(
                icon: iconData,
                tooltip: item.$1,
                decoration: const MyIconButtonDecoration(
                  iconColor: InteractiveColorSettings(color: Colors.black),
                  backgroundColor: InteractiveColorSettings(
                    color: Colors.white,
                    hoverColor: Color.fromARGB(255, 210, 210, 210),
                    selectedColor: Color.fromARGB(255, 107, 107, 107),
                  ),
                  borderRadius: 12,
                ),
                isSelected: icon == iconData,
                primaryAction: (_) {
                  icon = iconData;
                },
              );
            },
          ),
        );
      },
    );
  }
}
