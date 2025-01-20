import 'dart:ui';

import 'package:flutter/material.dart';

class MyIconButton extends StatefulWidget {
  /// Short tap or left click up
  final Function(TapUpDetails details) primaryAction;

  /// Long tap or right click up
  final Function(TapUpDetails details)? secondaryAction;
  final IconData icon;
  final String tooltip;
  final double? _size;
  final bool isSelected;
  final MyIconButtonDecoration decoration;

  double get size => _size ?? decoration.size;

  const MyIconButton({
    super.key,
    required this.icon,
    required this.primaryAction,
    this.secondaryAction,
    this.tooltip = "",
    double? size,
    this.decoration = const MyIconButtonDecoration(),
    this.isSelected = false,
  }) : _size = size;

  @override
  State<MyIconButton> createState() => _MyIconButtonState();
}

class _MyIconButtonState extends State<MyIconButton> {
  bool _isPressed = false;
  bool _isHover = false;
  MyIconButtonDecoration get d => widget.decoration;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      onEnter: (_) => startHover(),
      onExit: (_) => endHover(),
      child: Tooltip(
        message: widget.tooltip,
        preferBelow: true,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTapDown: (_) => startPress(),
          onTapUp: (details) {
            endPress();
            widget.primaryAction(details);
          },
          onSecondaryTapUp: (details) {
            endPress();
            if (widget.secondaryAction != null) {
              widget.secondaryAction!(details);
            }
          },
          onLongPressEnd: (longDetails) {
            endPress();
            if (widget.secondaryAction != null) {
              TapUpDetails details = TapUpDetails(
                kind: PointerDeviceKind.unknown,
                globalPosition: longDetails.globalPosition,
                localPosition: longDetails.localPosition,
              );
              widget.secondaryAction!(details);
            }
          },
          onTapCancel: () => startPress(),
          child: Container(
            padding: EdgeInsets.all(d.padding),
            decoration: BoxDecoration(
              color: d.backgroundColor
                  .getColor(_isPressed || widget.isSelected, _isHover),
              borderRadius: BorderRadius.circular(d.borderRadius),
            ),
            child: Icon(
              widget.icon,
              size: widget.size,
              color: d.iconColor
                  .getColor(_isPressed || widget.isSelected, _isHover),
            ),
          ),
        ),
      ),
    );
  }

  void startPress() {
    setState(() => _isPressed = true);
  }

  void endPress() {
    setState(() => _isPressed = false);
  }

  void startHover() {
    setState(() => _isHover = true);
  }

  void endHover() {
    setState(() => _isHover = false);
  }
}

class MyIconButtonDecoration {
  final double size;

  final InteractiveColorSettings iconColor;
  final InteractiveColorSettings backgroundColor;

  final double borderRadius;
  final double padding;

  const MyIconButtonDecoration({
    this.size = 24.0,
    this.iconColor = const InteractiveColorSettings(color: Colors.black),
    this.backgroundColor =
        const InteractiveColorSettings(color: Colors.transparent),
    this.borderRadius = 8.0,
    this.padding = 2.0,
  });

  MyIconButtonDecoration copyWith({
    double? size,
    InteractiveColorSettings? iconColor,
    InteractiveColorSettings? backgroundColor,
    double? borderRadius,
    double? padding,
  }) {
    return MyIconButtonDecoration(
      size: size ?? this.size,
      iconColor: iconColor ?? this.iconColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
    );
  }
}

class InteractiveColorSettings {
  final Color color;
  final Color? selectedColor;
  final Color? hoverColor;

  const InteractiveColorSettings({
    required this.color,
    this.selectedColor,
    this.hoverColor,
  });

  Color getColor(bool isPressed, bool isHover) {
    if (isPressed && selectedColor != null) {
      return selectedColor!;
    } else if (isHover && hoverColor != null) {
      return hoverColor!;
    } else {
      return color;
    }
  }
}
