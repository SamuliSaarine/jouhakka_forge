import 'package:flutter/material.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

class FloatingBar extends StatelessWidget {
  final FloatingBarDecoration decoration;
  final Axis direction;
  final List<Widget> children;

  const FloatingBar({
    super.key,
    this.direction = Axis.horizontal,
    this.decoration = FloatingBarDecoration.shadowedLightMode,
    required this.children,
  }) : assert(children.length > 0, "FloatingBar must have children");

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: decoration.backgroundColor,
        borderRadius: BorderRadius.circular(decoration.borderRadius),
        boxShadow: decoration.shadow != null ? [decoration.shadow!] : null,
      ),
      child: children.length > 1
          ? Flex(
              direction: direction,
              mainAxisSize: MainAxisSize.min,
              children: children,
            )
          : children.first,
    );
  }
}

class FloatingBarDecoration {
  final Color backgroundColor;
  final double borderRadius;
  final BoxShadow? shadow;

  const FloatingBarDecoration({
    this.backgroundColor = MyColors.lighterCharcoal,
    this.borderRadius = 8,
    this.shadow,
  });

  static const FloatingBarDecoration flatLightMode = FloatingBarDecoration(
    backgroundColor: MyColors.darkerCharcoal,
    borderRadius: 12,
  );

  static const FloatingBarDecoration flatDarkMode = FloatingBarDecoration(
    backgroundColor: MyColors.lighterCharcoal,
    borderRadius: 12,
  );

  static const FloatingBarDecoration shadowedLightMode = FloatingBarDecoration(
    backgroundColor: MyColors.darkerCharcoal,
    borderRadius: 12,
    shadow: _lightShadow,
  );

  static const FloatingBarDecoration shadowedDarkMode = FloatingBarDecoration(
    backgroundColor: MyColors.lighterCharcoal,
    borderRadius: 12,
    shadow: _heavyShadow,
  );

  static const BoxShadow _lightShadow = BoxShadow(
    color: Color.fromARGB(64, 0, 0, 0),
    spreadRadius: 2,
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow _heavyShadow = BoxShadow(
    color: Color.fromARGB(128, 0, 0, 0),
    spreadRadius: 4,
    blurRadius: 8,
    offset: Offset(0, 4),
  );
}
