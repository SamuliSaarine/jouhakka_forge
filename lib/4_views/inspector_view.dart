import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/buttons/my_text_button.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

class InspectorView extends StatelessWidget {
  final ElementRoot root;
  const InspectorView(this.root, {super.key});

  //TODO: Make fixed size editable
  //TODO: Make decoration editable
  //TODO: Implement editor for container elements
  //TODO: Implement editor for text elements
  //TODO: Implement editor for image elements
  @override
  Widget build(BuildContext context) {
    bool isPage = root is Page;
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(-1, 0),
          ),
        ],
      ),
      child: ValueListener(
        source: Session.selectedElement,
        builder: (element) {
          if (element == null) {
            return _rootInspector(isPage);
          } else {
            return _elementInspector(element);
          }
        },
      ),
    );
  }

  Widget _elementInspector(UIElement element) {
    const MyTextButtonDecoration sizeTypeDecoration = MyTextButtonDecoration(
      padding: 4,
      borderRadius: 4,
      backgroundColor: InteractiveColorSettings(
        color: Colors.blueGrey,
        hoverColor: Color.fromARGB(255, 66, 86, 96),
        selectedColor: Color.fromARGB(255, 40, 53, 60),
      ),
    );

    return Column(
      children: [
        Text(element.id),
        Text(element.label),
        ChangeListener(
          source: element.width,
          builder: () => Column(
            children: [
              Text("Width: ${element.width.value}"),
              FloatingBar(
                children: [
                  MyTextButton(
                    text: "Expand",
                    decoration: sizeTypeDecoration,
                    isSelected: element.width.type == SizeType.expand,
                    primaryAction: (_) {
                      element.width.type = SizeType.expand;
                    },
                  ),
                  MyTextButton(
                    text: "Auto",
                    decoration: sizeTypeDecoration,
                    isSelected: element.width.type == SizeType.auto,
                    primaryAction: (_) {
                      element.width.type = SizeType.auto;
                    },
                  ),
                  MyTextButton(
                    text: "Fixed",
                    decoration: sizeTypeDecoration,
                    isSelected: element.width.type == SizeType.fixed,
                    primaryAction: (_) {
                      element.width.type = SizeType.fixed;
                    },
                  ),
                ],
              ),
              if (element.width.type != SizeType.fixed)
                Text(
                    "Min: ${element.width.minPixels} Max: ${element.width.maxPixels}"),
            ],
          ),
        ),
        ChangeListener(
          source: element.height,
          builder: () => Column(
            children: [
              Text("Height: ${element.height.value}"),
              FloatingBar(
                children: [
                  MyTextButton(
                    text: "Expand",
                    decoration: sizeTypeDecoration,
                    isSelected: element.height.type == SizeType.expand,
                    primaryAction: (_) {
                      element.height.type = SizeType.expand;
                    },
                  ),
                  MyTextButton(
                    text: "Auto",
                    decoration: sizeTypeDecoration,
                    isSelected: element.height.type == SizeType.auto,
                    primaryAction: (_) {
                      element.height.type = SizeType.auto;
                    },
                  ),
                  MyTextButton(
                    text: "Fixed",
                    decoration: sizeTypeDecoration,
                    isSelected: element.height.type == SizeType.fixed,
                    primaryAction: (_) {
                      element.height.type = SizeType.fixed;
                    },
                  ),
                ],
              ),
              if (element.height.type != SizeType.fixed)
                Text(
                    "Min: ${element.height.minPixels} Max: ${element.height.maxPixels}"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rootInspector(bool isPage) {
    return const Column(
      children: [],
    );
  }
}
