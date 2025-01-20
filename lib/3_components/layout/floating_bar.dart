import 'dart:ui';

import 'package:flutter/material.dart';

class FloatingBar extends StatelessWidget {
  final Color backgroundColor;
  final double borderRadius;
  final BoxShadow? shadow;
  final Axis direction;
  final List<Widget> children;

  const FloatingBar({
    super.key,
    this.backgroundColor = Colors.white,
    this.borderRadius = 8,
    this.shadow = const BoxShadow(
      color: Color(0x28000000),
      spreadRadius: 1,
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    this.direction = Axis.horizontal,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: shadow != null ? [shadow!] : null,
          ),
          child: Flex(
            direction: direction,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
