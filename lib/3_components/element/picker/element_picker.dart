import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_category_row.dart';

class ElementPicker extends StatefulWidget {
  final Function(UIElement) onElementSelected;
  final ElementRoot root;
  final UIElement? parent;
  const ElementPicker(
      {super.key,
      required this.onElementSelected,
      required this.root,
      this.parent});

  @override
  State<ElementPicker> createState() => _ElementPickerState();
}

class _ElementPickerState extends State<ElementPicker> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: [
        ElementCategoryRow(
          "Basic",
          items: const [
            ElementButtonData("Empty", type: UIElementType.empty),
            ElementButtonData("Box", type: UIElementType.box)
          ],
          onElementSelected: (type) => widget.onElementSelected(
            UIElement.fromType(type, widget.root, widget.parent),
          ),
        ),
        ElementCategoryRow(
          "Media",
          items: const [
            ElementButtonData("Text", type: UIElementType.text),
            ElementButtonData("Image", type: UIElementType.image)
          ],
          onElementSelected: (type) => widget.onElementSelected(
            UIElement.fromType(type, widget.root, widget.parent),
          ),
        ),
      ]),
    );
  }
}

class ElementButtonData {
  final String title;
  final IconData icon;
  final Color iconColor;
  final UIElementType type;
  final ShortcutActivator? shortcutActivator;
  const ElementButtonData(
    this.title, {
    this.icon = Icons.square_outlined,
    this.iconColor = Colors.black,
    this.shortcutActivator,
    required this.type,
  });
}

enum UIElementType {
  empty,
  box,
  text,
  image,
}
