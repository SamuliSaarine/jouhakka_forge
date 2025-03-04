import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';

class MyTextButton extends StatefulWidget {
  /// Short tap or left click up
  final Function(TapUpDetails details) primaryAction;

  /// Long tap or right click up
  final Function(TapUpDetails details)? secondaryAction;
  final String text;
  final String tooltip;
  final double? _size;
  final bool isSelected;
  final MyTextButtonDecoration decoration;

  double get size => _size ?? decoration.size;

  const MyTextButton({
    super.key,

    /// What would icon button be without an icon?
    required this.text,

    /// Short tap or left click up
    required this.primaryAction,

    /// Long tap or right click up
    this.secondaryAction,

    /// Tooltip to show on hover
    this.tooltip = "",

    /// If you want to override icon size given in the decoration
    double? size,

    /// Visual settings for the button
    this.decoration = const MyTextButtonDecoration(),

    /// If true, toggle's the button's appearance to same as when pressed
    this.isSelected = false,
  }) : _size = size;

  @override
  State<MyTextButton> createState() => _MyTextButtonState();
}

class _MyTextButtonState extends State<MyTextButton> {
  bool _isPressed = false;
  bool _isHover = false;
  MyTextButtonDecoration get d => widget.decoration;

  @override
  Widget build(BuildContext context) {
    // Handle hover events
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      onEnter: (_) => startHover(),
      onExit: (_) => endHover(),
      child: Tooltip(
        message: widget.tooltip,
        preferBelow: true,
        waitDuration: const Duration(milliseconds: 500),
        // Handle press events
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
          // Building the visual part of the button
          child: Container(
            padding: EdgeInsets.all(d.padding),
            decoration: BoxDecoration(
              color: d.backgroundColor
                  .getColor(_isPressed || widget.isSelected, _isHover),
              borderRadius: BorderRadius.circular(d.borderRadius),
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.size,
                color: d.textColor
                    .getColor(_isPressed || widget.isSelected, _isHover),
              ),
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

class MyTextButtonDecoration {
  final double size;

  final InteractiveColorSettings textColor;
  final InteractiveColorSettings backgroundColor;

  final double borderRadius;
  final double padding;

  /// Visual settings for [MyTextButton]
  const MyTextButtonDecoration({
    /// Size of the icon
    this.size = 24.0,

    /// Interactive color settings for the icon
    this.textColor = const InteractiveColorSettings(color: Colors.black),

    /// Interactive color settings for the container
    this.backgroundColor =
        const InteractiveColorSettings(color: Colors.transparent),

    /// Border radius of the container
    this.borderRadius = 8.0,

    /// Padding between the icon and the borders of the container
    this.padding = 2.0,
  });

  /// Copy other [MyIconButtonDecoration] with some values overridden
  MyTextButtonDecoration copyWith({
    /// Size of the icon
    double? size,

    /// Interactive color settings for the icon
    InteractiveColorSettings? textColor,

    /// Interactive color settings for the container
    InteractiveColorSettings? backgroundColor,

    /// Border radius of the container
    double? borderRadius,

    /// Padding between the icon and the borders of the container
    double? padding,
  }) {
    return MyTextButtonDecoration(
      size: size ?? this.size,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
    );
  }
}
