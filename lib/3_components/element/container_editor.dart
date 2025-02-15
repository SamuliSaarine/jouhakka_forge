import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/1_helpers/functions.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';

class ContainerChildEditor extends StatelessWidget {
  final Widget elementWidget;
  final bool show;
  final void Function(AddDirection direction, {TapUpDetails? details})?
      onAddChild;

  const ContainerChildEditor({
    super.key,
    required this.elementWidget,
    this.show = false,
    this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError("Use inherited class or named constructor");
  }

  factory ContainerChildEditor.from(
    ContainerElement element, {
    required bool show,
    void Function(AddDirection direction, {TapUpDetails? details})? onAddChild,
    required Widget Function(UIElement child, int index) builder,
  }) {
    debugPrint("SingleChildEditor.build ${element.id}");

    Widget child(UIElement child, int index) {
      return builder(child, index);
    }

    List<Widget> children = [
      for (int i = 0; i < element.children.length; i++)
        child(element.children[i], i)
    ];

    if (element.type is FlexElementType) {
      Axis direction = (element.type as FlexElementType).direction;
      bool axisAutoSize = direction == Axis.vertical
          ? element.height.type == SizeType.auto
          : element.width.type == SizeType.auto;

      return FlexChildEditor(
        direction,
        key: ValueKey("${element.hashCode}_c"),
        autoSize: axisAutoSize,
        show: show,
        elementWidget: element.type.getWidget(children),
        onAddChild: onAddChild,
      );
    } else if (element.type is SingleChildElementType) {
      return SingleChildEditor(
        key: ValueKey("${element.hashCode}_c"),
        autoHeight: element.height.type == SizeType.auto,
        autoWidth: element.width.type == SizeType.auto,
        show: show,
        elementWidget: element.type.getWidget(children),
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
        primaryAction: (_) {
          onAddChild?.call(direction);
        },
        secondaryAction: (details) {
          onAddChild?.call(direction, details: details);
        },
      ),
    );
  }
}

class FlexChildEditor extends ContainerChildEditor {
  final Axis direction;
  final bool autoSize;

  bool get isVertical => direction == Axis.vertical;

  const FlexChildEditor(
    this.direction, {
    super.key,
    required this.autoSize,
    super.show,
    super.onAddChild,
    required super.elementWidget,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (!show) {
            return elementWidget;
          }

          debugPrint("FlexChildEditor: $constraints");

          MainAxisSize mainAxisSize = autoSize &&
                  (isVertical
                      ? constraints.maxHeight.isInfinite
                      : constraints.maxWidth.isInfinite)
              ? MainAxisSize.min
              : MainAxisSize.max;

          double buttonSize =
              fastSqrt(min(constraints.maxWidth, constraints.maxHeight));

          Widget current = elementWidget;
          if (mainAxisSize == MainAxisSize.max) {
            current = Expanded(child: current);
          }

          return Flex(
            mainAxisSize: mainAxisSize,
            direction: direction,
            children: [
              button(
                isVertical ? AddDirection.top : AddDirection.left,
                buttonSize,
              ),
              current,
              button(
                isVertical ? AddDirection.bottom : AddDirection.right,
                buttonSize,
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint("FlexChildEditor.build error: $e");
      rethrow;
    }
  }
}

class SingleChildEditor extends ContainerChildEditor {
  final bool autoWidth;
  final bool autoHeight;

  const SingleChildEditor({
    super.key,
    required this.autoWidth,
    required this.autoHeight,
    super.show = false,
    super.onAddChild,
    required super.elementWidget,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (!show) {
            return elementWidget;
          }

          double buttonSize =
              fastSqrt(min(constraints.maxWidth, constraints.maxHeight));

          Widget current = elementWidget;

          MainAxisSize horizontalAxisSize =
              autoWidth && constraints.maxWidth.isInfinite
                  ? MainAxisSize.min
                  : MainAxisSize.max;
          MainAxisSize verticalAxisSize =
              autoHeight && constraints.maxHeight.isInfinite
                  ? MainAxisSize.min
                  : MainAxisSize.max;

          debugPrint(
              "Horizontal: $horizontalAxisSize, Vertical: $verticalAxisSize");

          if (horizontalAxisSize == MainAxisSize.max) {
            current = Expanded(child: current);
          }

          current = Flex(
            direction: Axis.horizontal,
            mainAxisSize: horizontalAxisSize,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              button(AddDirection.left, buttonSize),
              current,
              button(AddDirection.right, buttonSize),
            ],
          );

          if (verticalAxisSize == MainAxisSize.max) {
            current = Expanded(child: current);
          }

          return Flex(
            direction: Axis.vertical,
            mainAxisSize: verticalAxisSize,
            children: [
              button(AddDirection.top, buttonSize),
              current,
              button(AddDirection.bottom, buttonSize),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint("SingleChildEditor.build error: $e");
      rethrow;
    }
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
