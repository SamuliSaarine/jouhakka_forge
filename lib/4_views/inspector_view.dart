import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

class InspectorView extends StatelessWidget {
  final ElementRoot root;
  const InspectorView(this.root, {super.key});

  //TODO: Make size type editable
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
    return Column(
      children: [
        Text(element.id),
        Text(element.runtimeType.toString()),
        ChangeListener(
          source: element.width,
          builder: () => Text("Width: ${element.width.toString()}"),
        ),
        ChangeListener(
          source: element.height,
          builder: () => Text("Height: ${element.height.toString()}"),
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
