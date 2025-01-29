import 'package:flutter/material.dart';

class ContextPopup {
  static OverlayEntry? _overlayEntry;
  static OverlayEntry? _secondaryEntry;

  /// Open a context menu with default builder.
  static void open(
    BuildContext context, {
    required Offset clickPosition,
    required Widget child,
    bool secondary = false,
  }) {
    // Close any existing context menu
    close();

    OverlayEntry entry = OverlayEntry(
      builder: (_) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              if (!secondary)
                GestureDetector(
                  onTap: close,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              Positioned(
                left: clickPosition.dx,
                top: clickPosition.dy,
                child: child,
              )
            ],
          ),
        );
      },
    );

    if (secondary) {
      _secondaryEntry = entry;
    } else {
      _overlayEntry = entry;
    }

    // Insert the overlay
    Overlay.of(context).insert(entry);
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

  static void closeSecondary() {
    _secondaryEntry?.remove();
    _secondaryEntry = null;
  }
}
