import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';

class ContainerChildEditor extends StatelessWidget {
  final Widget elementWidget;
  final bool show;
  final double buttonSize;
  final void Function(AddDirection direction, {TapUpDetails? details})?
      onAddChild;

  const ContainerChildEditor({
    super.key,
    required this.elementWidget,
    required this.buttonSize,
    this.show = false,
    this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError("Use inherited class or named constructor");
  }

  factory ContainerChildEditor.from(
    ElementContainer container, {
    required bool show,
    required double buttonSize,
    void Function(AddDirection direction, {TapUpDetails? details})? onAddChild,
    required Widget Function(UIElement child, int index) builder,
  }) {
    debugPrint("SingleChildEditor.build ${container.element.id}");

    Widget child(UIElement child, int index) {
      return builder(child, index);
    }

    List<Widget> children = [
      for (int i = 0; i < container.children.length; i++)
        child(container.children[i], i)
    ];

    if (container.type is FlexElementType) {
      Axis direction = (container.type as FlexElementType).direction;
      bool axisAutoSize = container.element.size.shrinks(axis: direction);

      return FlexChildEditor(
        direction,
        key: ValueKey("${container.hashCode}_c"),
        autoSize: axisAutoSize,
        show: show,
        buttonSize: buttonSize,
        elementWidget: container.type.getWidget(children),
        onAddChild: onAddChild,
      );
    } else if (container.type is SingleChildElementType) {
      return SingleChildEditor(
        key: ValueKey("${container.hashCode}_c"),
        autoHeight: container.element.size.height is ShrinkingSize,
        autoWidth: container.element.size.width is ShrinkingSize,
        show: show,
        buttonSize: buttonSize,
        elementWidget: container.type.getWidget(children),
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
    required super.buttonSize,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return elementWidget;
    }

    MainAxisSize mainAxisSize = autoSize ? MainAxisSize.min : MainAxisSize.max;

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
    required super.buttonSize,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return elementWidget;
    }

    Widget current = elementWidget;

    MainAxisSize horizontalAxisSize =
        autoWidth ? MainAxisSize.min : MainAxisSize.max;
    MainAxisSize verticalAxisSize =
        autoHeight ? MainAxisSize.min : MainAxisSize.max;

    debugPrint("Horizontal: $horizontalAxisSize, Vertical: $verticalAxisSize");

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

  static AddDirection fromString(String value) {
    switch (value) {
      case "top":
        return AddDirection.top;
      case "bottom":
        return AddDirection.bottom;
      case "left":
        return AddDirection.left;
      case "right":
        return AddDirection.right;
      case "vertical":
        debugPrint("Gaven vertical, returning bottom");
        return AddDirection.bottom;
      case "horizontal":
        debugPrint("Gaven horizontal, returning right");
        return AddDirection.right;
    }
    throw Exception("Invalid AddDirection: $value");
  }
}
