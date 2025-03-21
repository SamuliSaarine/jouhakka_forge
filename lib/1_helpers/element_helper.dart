import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';

extension ElementHelper on UIElement {}

extension BranchElementHelper on BranchElement {
  void addElement(UIElementType? type, AddDirection? direction) {
    ElementContainer? container = content.value;
    if (container == null) {
      content.value = ElementContainer.singleChildFromType(
        element: this,
        childType: type ?? UIElementType.box,
      );
    } else {
      if (container.type is SingleChildElementType) {
        container.changeContainerType(
            FlexElementType(direction?.axis ?? Axis.vertical));
      }
      UIElement? pickedElement;
      if (type != null) {
        pickedElement = UIElement.fromType(type, root, container);
      }
      if (pickedElement == null) {
        if (container.children.isEmpty) {
          pickedElement = BranchElement.defaultBox(root, parent: container);
        } else {
          pickedElement = container.children.last.clone();
        }
      }
      container.addChild(pickedElement);
    }
  }
}

extension LeafElementHelper on LeafElement {}
