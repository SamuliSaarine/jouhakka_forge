import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import '../3_components/element/ui_element_component.dart';

class ContainerElement extends UIElement {
  final List<UIElement> children;
  ContainerElementType type;

  ContainerElement({
    required this.children,
    required this.type,
    required super.root,
    required super.parent,
  });

  void addChild(UIElement child) {
    if (type is SingleChildElementType) {
      throw Exception(
          "SingleChildElementType can only have one child. Change the container type first.");
    }

    children.add(child);
  }

  void removeChild(UIElement child) {
    children.remove(child);
  }

  void reorderChild(int oldIndex, int newIndex) {
    final UIElement child = children.removeAt(oldIndex);
    children.insert(newIndex, child);
  }

  void changeContainerType(ContainerElementType newType) {
    type = newType;
  }

  factory ContainerElement.from(UIElement element,
      {required ContainerElementType type, required List<UIElement> children}) {
    return ContainerElement(
        children: children,
        type: type,
        root: element.root,
        parent: element.parent)
      ..width = element.width
      ..height = element.height
      ..decoration = element.decoration
      ..padding = element.padding;
  }

  @override
  Widget? getContent() {
    if (children.isEmpty) return null;
    if (children.length == 1) return children[0].widget();
    return type.getWidget((children.map((e) => e.widget()).toList()));
  }
}

abstract class ContainerElementType {
  Widget getWidget(List<Widget> children);
}

class SingleChildElementType extends ContainerElementType {
  @override
  Widget getWidget(List<Widget> children) {
    if (children.length != 1) {
      throw Exception(
          "SingleChildElementType can only have one child. Try to change the container type.");
    }
    return children[0];
  }
}

class ColumnElementType extends ContainerElementType {
  double? spacing;
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start;
  VerticalDirection verticalDirection = VerticalDirection.down;

  @override
  Widget getWidget(List<Widget> children) {
    if (spacing != null && children.length > 1) {
      // Add sized box between each child
      List<Widget> spacedChildren = [];
      for (int i = 0; i < children.length; i++) {
        if (i != 0) {
          spacedChildren.add(SizedBox(height: spacing));
        }
        spacedChildren.add(children[i]);
      }
    }
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

//RowElement
class RowElementType extends ContainerElementType {
  double? spacing;
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start;

  @override
  Widget getWidget(List<Widget> children) {
    if (spacing != null && children.length > 1) {
      // Add sized box between each child
      List<Widget> spacedChildren = [];
      for (int i = 0; i < children.length; i++) {
        if (i != 0) {
          spacedChildren.add(SizedBox(width: spacing));
        }
        spacedChildren.add(children[i]);
      }
    }
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

//StackElement
class StackElementType extends ContainerElementType {
  AlignmentGeometry alignment = AlignmentDirectional.topStart;
  StackFit fit = StackFit.loose;

  StackElementType(
      {this.alignment = AlignmentDirectional.topStart,
      this.fit = StackFit.loose});

  @override
  Widget getWidget(List<Widget> children) {
    return Stack(
      alignment: alignment,
      children: children,
    );
  }
}

//GridElement
class GridElementType extends ContainerElementType {
  int? crossAxisCount;
  double? crossAxisSpacing;
  double? mainAxisSpacing;
  double? childAspectRatio;
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start;

  @override
  Widget getWidget(List<Widget> children) {
    return GridView.count(
      crossAxisCount: crossAxisCount!,
      crossAxisSpacing: crossAxisSpacing!,
      mainAxisSpacing: mainAxisSpacing!,
      childAspectRatio: childAspectRatio!,
      children: children,
    );
  }
}
