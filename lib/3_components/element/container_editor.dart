import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/element/element_builder_interface.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/0_models/container_element.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';

class ContainerEditor extends StatefulWidget {
  final ContainerElement element;
  final bool isHovering;
  final bool showBorder;
  final void Function(AddDirection direction, UIElement element)? onAddChild;

  const ContainerEditor(
      {super.key,
      required this.element,
      this.showBorder = true,
      this.isHovering = false,
      this.onAddChild});

  @override
  State<ContainerEditor> createState() => _ContainerEditorState();
}

class _ContainerEditorState extends State<ContainerEditor> {
  ContainerElementType get type => widget.element.type;
  UIElement? hoveringChild;
  bool get notHovering => !widget.isHovering && hoveringChild == null;

  @override
  void dispose() {
    //debugPrint("ContainerEditor disposed");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget child;

        double buttonSize =
            sqrt(min(constraints.maxWidth, constraints.maxHeight)) * 2;

        if (type is ColumnElementType) {
          child = _vertical(buttonSize);
        } else if (type is RowElementType) {
          child = _horizontal(buttonSize);
        } else {
          child = _all(buttonSize);
        }

        if (widget.showBorder) {
          child = Container(
            decoration: BoxDecoration(
              border: widget.element.decoration == null
                  ? Border.all(color: Colors.blue, width: 0.5)
                  : Border.all(color: Colors.black, width: 1),
            ),
            child: child,
          );
        }

        return child;
      },
    );
  }

  Widget _vertical(double buttonSize) {
    Widget childColumn = Column(
      children: _childrenList(),
    );

    if (notHovering) {
      return childColumn;
      return Padding(
          padding: EdgeInsets.all(buttonSize / 4), child: childColumn);
    }

    if (widget.element.height.type == SizeType.expand) {
      childColumn = Expanded(child: childColumn);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: buttonSize / 2),
      child: Column(
        children: [
          _button(AddDirection.top, buttonSize),
          childColumn,
          _button(AddDirection.bottom, buttonSize),
        ],
      ),
    );
  }

  Widget _horizontal(double buttonSize) {
    Widget childRow = Row(
      children: _childrenList(),
    );

    if (notHovering) {
      return childRow;
      return Padding(padding: EdgeInsets.all(buttonSize / 4), child: childRow);
    }

    if (widget.element.width.type == SizeType.expand) {
      childRow = Expanded(child: childRow);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: buttonSize / 2),
      child: Row(
        children: [
          _button(AddDirection.left, buttonSize),
          childRow,
          _button(AddDirection.right, buttonSize),
        ],
      ),
    );
  }

  Widget _all(double buttonSize) {
    UIElement childElement = widget.element.children[0];

    Widget interface = _child(childElement);

    if (notHovering) {
      return interface;
      return Padding(padding: EdgeInsets.all(buttonSize / 4), child: interface);
    }

    if (childElement.width.type == SizeType.expand) {
      interface = Expanded(child: interface);
    }

    Widget row = Row(
      children: [
        _button(AddDirection.left, buttonSize),
        interface,
        _button(AddDirection.right, buttonSize),
      ],
    );

    if (childElement.height.type == SizeType.expand) {
      row = Expanded(child: row);
    }

    return Column(
      children: [
        _button(AddDirection.top, buttonSize),
        row,
        _button(AddDirection.bottom, buttonSize),
      ],
    );
  }

  Widget _button(AddDirection direction, double buttonSize) {
    return MyIconButton(
      icon: Icons.add,
      size: buttonSize,
      primaryAction: (details) {
        if (type is SingleChildElementType) {
          bool isColumn =
              direction == AddDirection.top || direction == AddDirection.bottom;
          ContainerElementType newType =
              isColumn ? ColumnElementType() : RowElementType();
          widget.element.changeContainerType(newType);
        }
        UIElement newElement =
            UIElement.defaultBox(widget.element.root, parent: widget.element);
        widget.element.addChild(newElement);
        if (widget.onAddChild != null) {
          widget.onAddChild!(
            direction,
            newElement,
          );
        }
        setState(() {});
      },
      secondaryAction: (details) {},
    );
  }

  List<Widget> _childrenList() {
    List<Widget> children = [];
    for (int i = 0; i < widget.element.children.length; i++) {
      UIElement childElement = widget.element.children[i];
      Widget child = _child(childElement, index: i);
      if (childElement.expands()) {
        child = Expanded(child: child);
      }
      children.add(
        child,
      );
      if (i < widget.element.children.length - 1) {
        children.add(const SizedBox(
          height: 8,
          width: 8,
        ));
      }
    }
    return children;
  }

  Widget _child(UIElement element, {int index = 0}) {
    return ElementBuilderInterface(
      key: ValueKey("${element.hashCode}_i"),
      element: element,
      onBodyChanged: (element) => _onChildChanged(element, index: index),
      isHovering: element == hoveringChild,
      onHoverChange: (hovering) {
        if (hoveringChild == element && !hovering) {
          setState(() {
            hoveringChild = null;
          });
        } else if (hovering) {
          setState(() {
            hoveringChild = element;
          });
        }
      },
    );
  }

  void _onChildChanged(UIElement element, {int index = 0}) {
    widget.element.children[index] = element;
    if (mounted) {
      setState(() {});
    }
  }
}

enum AddDirection { top, bottom, left, right }
