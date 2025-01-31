import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const Map<String, List<ElementButtonData>> _categories = {
    "Basic": [
      ElementButtonData("Empty",
          type: UIElementType.empty,
          shortcutActivator: SingleActivator(LogicalKeyboardKey.keyE)),
      ElementButtonData("Box",
          type: UIElementType.box,
          shortcutActivator: SingleActivator(LogicalKeyboardKey.keyB)),
    ],
    "Media": [
      ElementButtonData("Text",
          type: UIElementType.text,
          icon: Icons.text_fields,
          shortcutActivator: SingleActivator(LogicalKeyboardKey.keyT)),
      ElementButtonData("Icon",
          type: UIElementType.icon,
          icon: Icons.star,
          shortcutActivator: SingleActivator(LogicalKeyboardKey.keyI)),
      ElementButtonData("Image",
          type: UIElementType.image,
          icon: Icons.image,
          shortcutActivator: SingleActivator(LogicalKeyboardKey.keyM)),
    ],
  };

  Map<ShortcutActivator, VoidCallback> shortcuts = {};

  late FocusNode focusNode;

  @override
  void initState() {
    focusNode = FocusNode();
    focusNode.requestFocus();
    List<ElementButtonData> items =
        _categories.values.expand((e) => e).toList();
    for (ElementButtonData item in items) {
      if (item.shortcutActivator == null) continue;
      shortcuts[item.shortcutActivator!] = () {
        widget.onElementSelected(
          UIElement.fromType(item.type, widget.root, widget.parent),
        );
      };
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        focusNode: focusNode,
        child: Container(
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
            for (String category in _categories.keys)
              ElementCategoryRow(
                category,
                items: _categories[category]!,
                onElementSelected: (type) {
                  widget.onElementSelected(
                    UIElement.fromType(type, widget.root, widget.parent),
                  );
                },
              ),
          ]),
        ),
      ),
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
  icon,
}
