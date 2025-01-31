import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/buttons/my_text_button.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';
import 'package:jouhakka_forge/4_views/inspector_modules.dart';

class InspectorView extends StatelessWidget {
  final ElementRoot root;
  const InspectorView(this.root, {super.key});

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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(element.id),
        Text(element.label),
        if (element.parent != null) ...[
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: element.width.getEditor("Width")),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: element.height.getEditor("Height"),
          ),
        ],
        if (element.parent == null)
          const Text("Root element's size is fixed to resolution"),
      ],
    );
  }

  Widget _rootInspector(bool isPage) {
    return const Column(
      children: [],
    );
  }
}
