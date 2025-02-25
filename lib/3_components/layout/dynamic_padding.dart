import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

class DynamicPadding extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double extraPadding;
  const DynamicPadding(
      {super.key,
      required this.padding,
      required this.extraPadding,
      required this.child});

  @override
  State<DynamicPadding> createState() => _DynamicPaddingState();
}

class _DynamicPaddingState extends State<DynamicPadding> {
  @override
  Widget build(BuildContext context) {
    if (widget.padding == null) {
      return ValueListener(
          source: Session.extraPadding,
          builder: (apply) {
            if (apply) {
              return Padding(
                padding: EdgeInsets.all(widget.extraPadding),
                child: widget.child,
              );
            }
            return widget.child;
          });
    }
    EdgeInsets minPadding = widget.padding!;
    EdgeInsets paddingWithExtra = EdgeInsets.only(
      bottom: max(widget.extraPadding, minPadding.bottom),
      top: max(widget.extraPadding, minPadding.top),
      left: max(widget.extraPadding, minPadding.left),
      right: max(widget.extraPadding, minPadding.right),
    );
    return ValueListener(
      source: Session.extraPadding,
      builder: (apply) {
        return Padding(
          padding: apply ? paddingWithExtra : minPadding,
          child: widget.child,
        );
      },
    );
  }
}
