import 'package:flutter/material.dart';

class ContextMenu {
  static OverlayEntry? _overlayEntry;

  /// Open a context menu with default builder.
  static void open(
    BuildContext context, {
    required Offset clickPosition,
    required Widget child,
  }) {
    // Close any existing context menu
    close();

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return Material(
          type: MaterialType.transparency,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Default position is the click position
              double dx = clickPosition.dx;
              double dy = clickPosition.dy;

              return Stack(
                children: [
                  GestureDetector(
                    onTap: close,
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                  Positioned(
                    left: dx,
                    top: dy,
                    child: child,
                  )
                ],
              );
            },
          ),
        );
      },
    );

    // Insert the overlay
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Open a context menu with custom builder.
  static void build(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
  }) {
    // Close any existing context menu
    close();

    _overlayEntry = OverlayEntry(
      builder: builder,
    );

    // Insert the overlay
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
