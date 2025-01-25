import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import '../3_components/element/ui_element_component.dart';

class ContainerElement extends UIElement {
  /// List of [UIElement]s that are direct children of this container.
  final List<UIElement> children;

  /// Specifies how the [ContainerElement] acts and is displayed.
  ContainerElementType type;

  /// [UIElement] that can contain one or more [UIElement]s.
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

  /// Creates a [ContainerElement] from a [UIElement].
  ///
  /// Useful if you want to keep decoration or size settings from the original element.
  factory ContainerElement.from(UIElement element,
      {required ContainerElementType type, required List<UIElement> children}) {
    return ContainerElement(
        children: children,
        type: type,
        root: element.root,
        parent: element.parent)
      ..width.copy(element.width)
      ..height.copy(element.height)
      ..decoration.value = element.decoration.value
      ..padding.value = element.padding.value;
  }

  /// Returns the content of the container.
  @override
  Widget? getContent() {
    if (children.isEmpty) return null;
    if (children.length == 1) return children[0].widget();
    List<Widget> widgetChildren = children.map((e) => e.widget()).toList();
    if (type is FlexElementType) {
      AxisSize axisSize = (type as FlexElementType).direction == Axis.horizontal
          ? width
          : height;
      bool hugContent = axisSize.type == SizeType.auto;
      return (type as FlexElementType).getWidget(
        widgetChildren,
        mainAxisSize: hugContent ? MainAxisSize.min : MainAxisSize.max,
      );
    }
    return type.getWidget(widgetChildren);
  }

  @override
  String get label => type.label;
}

abstract class ContainerElementType {
  /// Returns a [Widget] that contains the children.
  Widget getWidget(List<Widget> children);
  String get label;
}

class SingleChildElementType extends ContainerElementType {
  /// [ContainerElementType] that can only have one child.
  SingleChildElementType();

  @override
  Widget getWidget(List<Widget> children) {
    if (children.length != 1) {
      throw Exception(
          "SingleChildElementType can only have one child. Try to change the container type.");
    }
    return children[0];
  }

  @override
  String get label => "Container";
}

class FlexElementType extends ContainerElementType {
  double? spacing;
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.end;
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center;
  Axis direction = Axis.vertical;

  /// [ContainerElementType] that arranges children in a row or column.
  FlexElementType(
    this.direction, {
    this.spacing,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget getWidget(List<Widget> children,
      {MainAxisSize mainAxisSize = MainAxisSize.max}) {
    if (spacing != null && children.length > 1) {
      // Add sized box between each child
      List<Widget> spacedChildren = [];
      for (int i = 0; i < children.length; i++) {
        if (i != 0) {
          spacedChildren.add(SizedBox(
            width: direction == Axis.horizontal ? spacing : null,
            height: direction == Axis.vertical ? spacing : null,
          ));
        }
        spacedChildren.add(children[i]);
      }
    }
    return Flex(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      direction: direction,
      children: children,
    );
  }

  @override
  String get label => "Flex";
}

//StackElement
class StackElementType extends ContainerElementType {
  AlignmentGeometry alignment = AlignmentDirectional.topStart;
  StackFit fit = StackFit.loose;

  /// [ContainerElementType] that arranges children in a stack.
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

  @override
  String get label => "Stack";
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

  @override
  String get label => "Grid";
}
