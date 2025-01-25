import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/1_helpers/functions.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/0_models/container_element.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';

class ContainerChildEditor extends StatelessWidget {
  final Widget elementWidget;
  final bool isHovering;
  final void Function(AddDirection direction)? onAddChild;

  const ContainerChildEditor({
    super.key,
    required this.elementWidget,
    this.isHovering = false,
    this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError("Use inherited class or named constructor");
  }

  factory ContainerChildEditor.from(
    ContainerElement element, {
    bool isHovering = false,
    void Function(AddDirection direction)? onAddChild,
    required Widget Function(UIElement child, int index) builder,
  }) {
    bool expandInner = false;
    Widget child(UIElement child, int index) {
      if (child.expands(axis: Axis.vertical)) {
        expandInner = true;
      }
      return builder(child, index);
    }

    List<Widget> children = [
      for (int i = 0; i < element.children.length; i++)
        child(element.children[i], i)
    ];

    if (element.type is FlexElementType) {
      Axis direction = (element.type as FlexElementType).direction;
      bool axisExpands = direction == Axis.vertical
          ? element.width.type == SizeType.expand
          : element.height.type == SizeType.expand;

      return FlexChildEditor(
        direction,
        key: ValueKey("${element.hashCode}_c"),
        mainAxisSize: axisExpands ? MainAxisSize.max : MainAxisSize.min,
        isHovering: isHovering,
        elementWidget: element.type.getWidget(children),
        onAddChild: onAddChild,
      );
    } else if (element.type is SingleChildElementType) {
      return SingleChildEditor(
        key: ValueKey("${element.hashCode}_c"),
        verticalAxisSize: element.height.type == SizeType.expand
            ? MainAxisSize.max
            : MainAxisSize.min,
        horizontalAxisSize: element.width.type == SizeType.expand
            ? MainAxisSize.max
            : MainAxisSize.min,
        isHovering: isHovering,
        expandInner: expandInner,
        elementWidget: children.first,
        onAddChild: onAddChild,
      );
    }

    throw Exception("Container type not supported");
  }

  Widget button(AddDirection direction, double buttonSize) {
    return Padding(
      padding: EdgeInsets.all(buttonSize * 0.2),
      child: MyIconButton(
        icon: Icons.add,
        size: buttonSize * 0.8,
        decoration: MyIconButtonDecoration(
          iconColor: const InteractiveColorSettings(color: Colors.white),
          backgroundColor: const InteractiveColorSettings(
            color: Colors.blue,
            hoverColor: Color.fromARGB(255, 25, 111, 182),
            selectedColor: Color.fromARGB(255, 17, 44, 67),
          ),
          borderRadius: buttonSize * 0.2,
        ),
        primaryAction: (details) {
          onAddChild?.call(direction);
        },
      ),
    );
  }
}

class FlexChildEditor extends ContainerChildEditor {
  final Axis direction;
  final MainAxisSize mainAxisSize;

  bool get isVertical => direction == Axis.vertical;

  const FlexChildEditor(
    this.direction, {
    super.key,
    this.mainAxisSize = MainAxisSize.min,
    super.isHovering,
    super.onAddChild,
    required super.elementWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!isHovering) {
          return elementWidget;
        }

        double buttonSize =
            fastSqrt(min(constraints.maxWidth, constraints.maxHeight)) * 2;

        return Flex(
          mainAxisSize: mainAxisSize,
          direction: direction,
          children: [
            button(
                isVertical ? AddDirection.top : AddDirection.left, buttonSize),
            Expanded(child: elementWidget),
            button(isVertical ? AddDirection.bottom : AddDirection.right,
                buttonSize),
          ],
        );
      },
    );
  }
}

class SingleChildEditor extends ContainerChildEditor {
  final MainAxisSize verticalAxisSize;
  final MainAxisSize horizontalAxisSize;
  final bool expandInner;

  const SingleChildEditor({
    super.key,
    this.verticalAxisSize = MainAxisSize.min,
    this.horizontalAxisSize = MainAxisSize.min,
    super.isHovering = false,
    super.onAddChild,
    this.expandInner = true,
    required super.elementWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!isHovering) {
          return elementWidget;
        }

        double buttonSize =
            fastSqrt(min(constraints.maxWidth, constraints.maxHeight)) * 2;

        Widget inner = Flex(
          direction: Axis.horizontal,
          mainAxisSize: horizontalAxisSize,
          children: [
            button(AddDirection.left, buttonSize),
            elementWidget,
            button(AddDirection.right, buttonSize),
          ],
        );

        if (expandInner) {
          inner = Expanded(child: inner);
        }

        return Flex(
          direction: Axis.vertical,
          mainAxisSize: verticalAxisSize,
          children: [
            button(AddDirection.top, buttonSize),
            inner,
            button(AddDirection.bottom, buttonSize),
          ],
        );
      },
    );
  }
}

enum AddDirection {
  top,
  bottom,
  left,
  right;

  Axis get axis => this == AddDirection.top || this == AddDirection.bottom
      ? Axis.vertical
      : Axis.horizontal;
}
