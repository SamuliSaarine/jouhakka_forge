import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClickDetector extends StatelessWidget {
  final void Function()? primaryAction;
  final void Function()? secondaryAction;
  final void Function(TapUpDetails details)? primaryActionWithDetails;
  final void Function(TapUpDetails details)? secondaryActionWithDetails;
  final void Function(PointerHoverEvent details)? onHover;
  final void Function(PointerEnterEvent details)? onEnter;
  final void Function(PointerExitEvent details)? onExit;
  final void Function(PointerEvent details)? onPointerEvent;
  final bool opaque;
  final Widget child;

  const ClickDetector({
    super.key,
    this.primaryAction,
    this.secondaryAction,
    this.primaryActionWithDetails,
    this.secondaryActionWithDetails,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.onPointerEvent,
    this.opaque = false,
    required this.child,
  })  : assert((primaryAction == null) != (primaryActionWithDetails == null),
            "Either primaryAction or primaryActionWithDetails must be provided. You can't provide both."),
        assert(secondaryAction == null || secondaryActionWithDetails == null,
            "You can't provide both secondaryAction and secondaryActionDetails"),
        assert(
            (onPointerEvent == null) ||
                (onEnter == null && onExit == null && onHover == null),
            "If you provide onPointerEvent, you can't provide onEnter, onExit or onHover");

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: onEnter ?? onPointerEvent,
      onExit: onExit ?? onPointerEvent,
      onHover: onHover ?? onPointerEvent,
      opaque: opaque,
      hitTestBehavior:
          opaque ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      child: GestureDetector(
        onTap: primaryAction,
        onLongPress: secondaryAction,
        onTapUp: primaryActionWithDetails,
        onLongPressEnd: (details) {
          if (secondaryActionWithDetails != null) {
            TapUpDetails newDetails = TapUpDetails(
                kind: PointerDeviceKind.mouse,
                globalPosition: details.globalPosition,
                localPosition: details.localPosition);
            secondaryActionWithDetails!(newDetails);
          }
        },
        onSecondaryTap: secondaryAction,
        onSecondaryTapUp: secondaryActionWithDetails,
        behavior: opaque ? HitTestBehavior.opaque : HitTestBehavior.translucent,
        child: child,
      ),
    );
  }
}
