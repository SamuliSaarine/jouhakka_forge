import 'dart:ui';

import 'package:flutter/material.dart';

class MyIconButton extends StatefulWidget {
  /// Short tap or left click up
  final Function(TapUpDetails details) primaryAction;

  /// Long tap or right click up
  final Function(TapUpDetails details)? secondaryAction;
  final String tooltip;
  final double size;
  final IconData icon;
  final InteractiveColorSettings iconColors;
  final InteractiveColorSettings backgroundColors;
  final double borderRadius;

  const MyIconButton({
    super.key,
    required this.icon,
    required this.primaryAction,
    this.secondaryAction,
    this.tooltip = "",
    this.iconColors = const InteractiveColorSettings(color: Colors.black),
    this.backgroundColors =
        const InteractiveColorSettings(color: Colors.transparent),
    this.size = 24.0,
    this.borderRadius = 8.0,
  });

  @override
  State<MyIconButton> createState() => _MyIconButtonState();
}

class _MyIconButtonState extends State<MyIconButton> {
  bool _isPressed = false;
  bool _isHover = false;

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
            decoration: BoxDecoration(
              color: widget.backgroundColors.getColor(_isPressed, _isHover),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Icon(
              widget.icon,
              size: widget.size,
              color: widget.iconColors.getColor(_isPressed, _isHover),
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
