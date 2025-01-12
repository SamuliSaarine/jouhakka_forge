import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:jouhakka_forge/3_components/buttons/my_titled_icon_button.dart';

class ElementCategoryRow extends StatelessWidget {
  final String title;
  final List<ElementButtonData> items;
  final Function(UIElementType) onElementSelected;

  const ElementCategoryRow(
    this.title, {
    required this.items,
    required this.onElementSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(title),
      Row(
        children: items.map((e) {
          return MyTitledIconButton(
            icon: e.icon,
            tooltip: "",
            title: e.title,
            onTap: () => onElementSelected(e.type),
          );
        }).toList(),
      ),
    ]);
  }
}
