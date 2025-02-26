import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClickDetector extends StatefulWidget {
  final void Function(TapDownDetails details)? primaryActionDown;
  final void Function(TapDownDetails details)? secondaryActionDown;
  final void Function(TapUpDetails details)? primaryActionUp;
  final void Function(TapUpDetails details)? secondaryActionUp;
  final void Function(PointerHoverEvent details)? onHover;
  final void Function(PointerEnterEvent details)? onEnter;
  final void Function(PointerExitEvent details)? onExit;
  final void Function(PointerEvent details)? onPointerEvent;
  final bool opaque;
  final Widget? child;
  final Widget Function(bool hovering, bool pressed)? builder;

  const ClickDetector({
    super.key,

    /// Called instantly when the primary button is pressed down.
    this.primaryActionDown,
    this.secondaryActionDown,

    /// Called when the primary button is released and regular tap gesture won (Not long press, canceled etc.).
    this.primaryActionUp,
    this.secondaryActionUp,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.onPointerEvent,
    this.opaque = true,

    /// This widget does not directly affect child state
    this.child,

    /// Hover and pressed states are provided directly to the builder
    this.builder,
  })  : assert((primaryActionDown == null) != (primaryActionUp == null),
            "Either primaryAction or primaryActionWithDetails must be provided. You can't provide both."),
        assert(secondaryActionDown == null || secondaryActionUp == null,
            "You can't provide both secondaryAction and secondaryActionDetails"),
        assert(
            (onPointerEvent == null) ||
                (onEnter == null && onExit == null && onHover == null),
            "If you provide onPointerEvent, you can't provide onEnter, onExit or onHover"),
        assert(
          (child != null) != (builder != null),
          "You must provide either a child or a builder. You can't provide both.",
        );

  @override
  State<ClickDetector> createState() => _ClickDetectorState();
}

class _ClickDetectorState extends State<ClickDetector> {
  bool get trackState => widget.builder != null;
  bool hovering = false;
  bool pressed = false;
  final SystemMouseCursor cursor = SystemMouseCursors.click;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      onEnter: _handleEnter,
      onExit: _handleExit,
      onHover: _handleHover,
      opaque: widget.opaque,
      hitTestBehavior:
          widget.opaque ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onSecondaryTapDown: _handleSecondaryTapDown,
        onSecondaryTapUp: _handleSecondaryTapUp,
        behavior: widget.opaque
            ? HitTestBehavior.opaque
            : HitTestBehavior.translucent,
        child: widget.child ?? widget.builder!(hovering, pressed),
      ),
    );
  }

  void _handleEnter(PointerEnterEvent event) {
    if (widget.onEnter != null) {
      widget.onEnter!(event);
    } else if (widget.onPointerEvent != null) {
      widget.onPointerEvent!(event);
    }
    if (trackState) {
      setState(() {
        hovering = true;
      });
    }
  }

  void _handleExit(PointerExitEvent event) {
    if (widget.onExit != null) {
      widget.onExit!(event);
    } else if (widget.onPointerEvent != null) {
      widget.onPointerEvent!(event);
    }
    if (hovering) {
      setState(() {
        hovering = false;
      });
    }
  }

  void _handleHover(PointerHoverEvent event) {
    if (widget.onHover != null) {
      widget.onHover!(event);
    } else if (widget.onPointerEvent != null) {
      widget.onPointerEvent!(event);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.primaryActionDown != null) {
      widget.primaryActionDown!(details);
    } else if (trackState) {
      setState(() {
        pressed = true;
      });
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (widget.secondaryActionDown != null) {
      TapDownDetails newDetails = TapDownDetails(
          kind: PointerDeviceKind.mouse,
          globalPosition: details.globalPosition,
          localPosition: details.localPosition);
      widget.secondaryActionDown!(newDetails);
    } else if (trackState && pressed == false) {
      setState(() {
        pressed = true;
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.primaryActionUp != null) {
      widget.primaryActionUp!(details);
    }

    if (pressed) {
      setState(() {
        pressed = false;
      });
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    TapUpDetails translateDetails() => TapUpDetails(
        kind: PointerDeviceKind.mouse,
        globalPosition: details.globalPosition,
        localPosition: details.localPosition);
    if (widget.secondaryActionUp != null) {
      widget.secondaryActionUp!(translateDetails());
    } else if (widget.primaryActionUp != null) {
      widget.primaryActionUp!(translateDetails());
    }

    if (pressed) {
      setState(() {
        pressed = false;
      });
    }
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    if (widget.secondaryActionDown != null) {
      widget.secondaryActionDown!(details);
    } else if (trackState) {
      setState(() {
        pressed = true;
      });
    }
  }

  void _handleSecondaryTapUp(TapUpDetails details) {
    if (widget.secondaryActionUp != null) {
      widget.secondaryActionUp!(details);
    }

    if (pressed) {
      setState(() {
        pressed = false;
      });
    }
  }
}
