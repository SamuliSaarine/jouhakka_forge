import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/layout/my_tooltip.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

class MyIconButton extends StatelessWidget {
  /// Short tap or left click up
  final Function(TapUpDetails details) primaryAction;

  /// Long tap or right click up
  final Function(TapUpDetails details)? secondaryAction;
  final IconData icon;
  final String tooltip;
  final double? _size;
  final bool isSelected;
  final bool isEnabled;
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

    /// If false, the button is disabled and doesn't react to any input
    this.isEnabled = true,

    /// Visual settings for the button
    this.decoration = const MyIconButtonDecoration(),

    /// If true, toggle's the button's appearance to same as when pressed
    this.isSelected = false,
  }) : _size = size;

  //bool _isPressed = false;
  MyIconButtonDecoration get d => decoration;

  @override
  Widget build(BuildContext context) {
    // Handle hover events
    Widget current = ClickDetector(
      primaryActionUp: (details) => primaryAction(details),
      secondaryActionUp: (details) {
        if (secondaryAction != null) {
          secondaryAction!(details);
        }
      },
      builder: (hovering, pressed) => Container(
        padding: EdgeInsets.all(d.padding),
        decoration: BoxDecoration(
          color: d.backgroundColor.getColor(pressed || isSelected, hovering),
          borderRadius: BorderRadius.circular(d.borderRadius),
          border: d.borderWidth == 0 || d.borderColor == null
              ? null
              : Border.all(
                  color:
                      d.borderColor!.getColor(pressed || isSelected, hovering),
                  width: d.borderWidth,
                ),
        ),
        child: Icon(
          icon,
          size: size,
          color:
              d.iconColor.getColor(pressed || isSelected, hovering, !isEnabled),
        ),
      ),
    );

    if (tooltip.isEmpty) {
      return current;
    }

    return MyTooltip(
      tooltip,
      child: current,
    );

    /*return MouseRegion(
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
    );*/
  }
}

class MyIconButtonDecoration {
  final double size;

  final InteractiveColorSettings iconColor;
  final InteractiveColorSettings backgroundColor;

  final InteractiveColorSettings? borderColor;
  final double borderWidth;

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

    /// Interactive color settings for the border
    this.borderColor,

    /// Width of the border
    this.borderWidth = 0.0,
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

  static const MyIconButtonDecoration onLightBackground =
      MyIconButtonDecoration(
    iconColor: InteractiveColorSettings(
      color: MyColors.slate,
      hoverColor: MyColors.dark,
      selectedColor: MyColors.darkMint,
    ),
    borderRadius: 0,
    backgroundColor: InteractiveColorSettings(
      color: Colors.transparent,
    ),
    padding: 2,
  );

  static const MyIconButtonDecoration onDarkBar6 = MyIconButtonDecoration(
    iconColor: InteractiveColorSettings(
        color: Colors.white,
        hoverColor: MyColors.lightMint,
        selectedColor: MyColors.lightMint),
    borderRadius: 0,
    backgroundColor: _transparentWhenSelected,
    padding: 6,
  );

  static const MyIconButtonDecoration onDarkBar8 = MyIconButtonDecoration(
    iconColor: InteractiveColorSettings(
      color: Colors.white,
      hoverColor: MyColors.lightMint,
      selectedColor: MyColors.lightMint,
      disabledColor: MyColors.strongDifference,
    ),
    borderRadius: 0,
    backgroundColor: _transparentWhenSelected,
    padding: 8,
  );

  static const MyIconButtonDecoration onDarkBar12 = MyIconButtonDecoration(
    iconColor: InteractiveColorSettings(color: Colors.white),
    borderRadius: 0,
    backgroundColor: _strongBackground,
    padding: 12,
  );

  static const _transparentWhenSelected = InteractiveColorSettings(
    color: Colors.transparent,
    hoverColor: MyColors.mildDifference,
    selectedColor: Colors.transparent,
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
  final Color? disabledColor;

  /// Color settings for interactive widgets
  const InteractiveColorSettings({
    required this.color,
    this.selectedColor,
    this.hoverColor,
    this.disabledColor,
  });

  Color getColor(bool isPressed, bool isHover, [bool isDisabled = false]) {
    if (isDisabled && disabledColor != null) {
      return disabledColor!;
    } else if (isPressed && selectedColor != null) {
      return selectedColor!;
    } else if (isHover && hoverColor != null) {
      return hoverColor!;
    } else {
      return color;
    }
  }
}
