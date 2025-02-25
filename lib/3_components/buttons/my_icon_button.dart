import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/layout/my_tooltip.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

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

    /// What would icon button be without an icon?
    required this.icon,

    /// Short tap or left click up
    required this.primaryAction,

    /// Long tap or right click up
    this.secondaryAction,

    /// Tooltip to show on hover
    this.tooltip = "",

    /// If you want to override icon size given in the decoration
    double? size,

    /// Visual settings for the button
    this.decoration = const MyIconButtonDecoration(),

    /// If true, toggle's the button's appearance to same as when pressed
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
    // Handle hover events
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      onEnter: (_) => startHover(),
      onExit: (_) => endHover(),
      child: MyTooltip(
        widget.tooltip,
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

  /// Visual settings for [MyIconButton]
  const MyIconButtonDecoration({
    /// Size of the icon
    this.size = 24.0,

    /// Interactive color settings for the icon
    this.iconColor = const InteractiveColorSettings(color: Colors.black),

    /// Interactive color settings for the container
    this.backgroundColor =
        const InteractiveColorSettings(color: Colors.transparent),

    /// Border radius of the container
    this.borderRadius = 8.0,

    /// Padding between the icon and the borders of the container
    this.padding = 2.0,
  });

  /// Copy other [MyIconButtonDecoration] with some values overridden
  MyIconButtonDecoration copyWith({
    /// Size of the icon
    double? size,

    /// Interactive color settings for the icon
    InteractiveColorSettings? iconColor,

    /// Interactive color settings for the container
    InteractiveColorSettings? backgroundColor,

    /// Border radius of the container
    double? borderRadius,

    /// Padding between the icon and the borders of the container
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

  static const MyIconButtonDecoration onDarkBar8 = MyIconButtonDecoration(
    iconColor: InteractiveColorSettings(color: Colors.white),
    borderRadius: 0,
    backgroundColor: _defaultBackground,
    padding: 8,
  );

  static const MyIconButtonDecoration onDarkBar12 = MyIconButtonDecoration(
    iconColor: InteractiveColorSettings(color: Colors.white),
    borderRadius: 0,
    backgroundColor: _strongBackground,
    padding: 12,
  );

  static const _defaultBackground = InteractiveColorSettings(
    color: Colors.transparent,
    hoverColor: MyColors.mildDifference,
    selectedColor: MyColors.mediumDifference,
  );
  static const _strongBackground = InteractiveColorSettings(
    color: Colors.transparent,
    hoverColor: MyColors.mediumDifference,
    selectedColor: MyColors.strongDifference,
  );
}

class InteractiveColorSettings {
  final Color color;
  final Color? selectedColor;
  final Color? hoverColor;

  /// Color settings for interactive widgets
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
