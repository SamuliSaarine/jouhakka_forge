import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/0_models/container_element.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';

abstract class ContainerChildEditor {
  Widget get elementWidget;
  bool get isHovering;
  void Function(AddDirection direction)? get onAddChild;
  void Function(Size sizeRequiredOnHover) get onButtonSizeUpdate;

  static Widget from(
    ContainerElement element, {
    bool isHovering = false,
    void Function(AddDirection direction)? onAddChild,
    required void Function(Size sizeRequiredOnHover) onButtonSizeUpdate,
    required List<Widget> children,
  }) {
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
        onButtonSizeUpdate: onButtonSizeUpdate,
        elementWidget: element.type.getWidget(children),
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
        expandInner: element.height.type == SizeType.expand,
        onButtonSizeUpdate: onButtonSizeUpdate,
        elementWidget: children.first,
      );
    }

    throw Exception("Container type not supported");
  }
}

class FlexChildEditor extends StatelessWidget implements ContainerChildEditor {
  @override
  final Widget elementWidget;
  @override
  final bool isHovering;
  @override
  final void Function(AddDirection direction)? onAddChild;
  @override
  final void Function(Size res) onButtonSizeUpdate;
  final Axis direction;
  final MainAxisSize mainAxisSize;

  bool get isVertical => direction == Axis.vertical;

  const FlexChildEditor(
    this.direction, {
    super.key,
    this.mainAxisSize = MainAxisSize.min,
    this.isHovering = false,
    this.onAddChild,
    required this.onButtonSizeUpdate,
    required this.elementWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double buttonSize =
            sqrt(min(constraints.maxWidth, constraints.maxHeight)).toInt() * 2;

        onButtonSizeUpdate(direction == Axis.vertical
            ? Size(0, buttonSize * 2)
            : Size(buttonSize * 2, 0));

        if (!isHovering) {
          return elementWidget;
        }

        return Flex(
          mainAxisSize: mainAxisSize,
          direction: direction,
          children: [
            _button(
                isVertical ? AddDirection.top : AddDirection.left, buttonSize),
            elementWidget,
            _button(isVertical ? AddDirection.bottom : AddDirection.right,
                buttonSize),
          ],
        );
      },
    );
  }

  _button(AddDirection direction, double buttonSize) {
    return MyIconButton(
      icon: Icons.add,
      size: buttonSize,
      primaryAction: (details) {
        onAddChild?.call(direction);
      },
    );
  }
}

class SingleChildEditor extends StatelessWidget
    implements ContainerChildEditor {
  @override
  final Widget elementWidget;
  @override
  final bool isHovering;
  @override
  final void Function(AddDirection direction)? onAddChild;
  @override
  final void Function(Size res) onButtonSizeUpdate;
  final MainAxisSize verticalAxisSize;
  final MainAxisSize horizontalAxisSize;
  final bool expandInner;

  const SingleChildEditor({
    super.key,
    this.verticalAxisSize = MainAxisSize.min,
    this.horizontalAxisSize = MainAxisSize.min,
    this.isHovering = false,
    this.onAddChild,
    this.expandInner = true,
    required this.onButtonSizeUpdate,
    required this.elementWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double buttonSize =
            sqrt(min(constraints.maxWidth, constraints.maxHeight)).toInt() * 2;

        onButtonSizeUpdate(Size(buttonSize * 2, buttonSize * 2));

        if (!isHovering) {
          return elementWidget;
        }

        Widget inner = Flex(
          direction: Axis.horizontal,
          mainAxisSize: horizontalAxisSize,
          children: [
            _button(AddDirection.left, buttonSize),
            elementWidget,
            _button(AddDirection.right, buttonSize),
          ],
        );

        if (expandInner) {
          inner = Expanded(child: inner);
        }

        return Flex(
          direction: Axis.vertical,
          mainAxisSize: verticalAxisSize,
          children: [
            _button(AddDirection.top, buttonSize),
            inner,
            _button(AddDirection.bottom, buttonSize),
          ],
        );
      },
    );
  }

  _button(AddDirection direction, double buttonSize) {
    return MyIconButton(
      icon: Icons.add,
      size: buttonSize,
      primaryAction: (details) {
        onAddChild?.call(direction);
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
