import 'dart:async';

import 'package:flutter/material.dart';

class ContextPopup {
  static OverlayEntry? _overlayEntry;
  static OverlayEntry? _secondaryEntry;
  static Completer<void>? _closeCompleter;
  static const double _additionalOffset = 10;

  /// Open a context menu with default builder.
  static void open(
    BuildContext context, {
    required Offset clickPosition,
    required Widget child,
    bool secondary = false,
    bool preferBottom = true,
  }) {
    // Close any existing context menu
    if (secondary) {
      closeSecondary();
    } else {
      close();
    }

    if (!secondary) {
      _closeCompleter = Completer<void>();
    }

    GlobalKey tooltipKey = GlobalKey();

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
                left: clickPosition.dx + _additionalOffset,
                top: preferBottom ? clickPosition.dy + _additionalOffset : null,
                bottom: preferBottom
                    ? null
                    : MediaQuery.of(context).size.height -
                        clickPosition.dy +
                        _additionalOffset,
                child: SizedBox(
                  key: tooltipKey,
                  child: child,
                ),
              ),
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

    //Post frame callback to calculate the position of the tooltip
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox =
          tooltipKey.currentContext!.findRenderObject() as RenderBox;
      final estimatedSize = renderBox.size;
      debugPrint("Estimated size: $estimatedSize");

      bool offsetFixed = false;
      Offset offset = Offset(
        clickPosition.dx + _additionalOffset,
        clickPosition.dy +
            (preferBottom ? _additionalOffset : -_additionalOffset),
      );

      // Checking horizontal bounds
      if (clickPosition.dx + estimatedSize.width + _additionalOffset >
          MediaQuery.of(context).size.width) {
        debugPrint("Tooltip is too far right");
        offset = Offset(
          clickPosition.dx - estimatedSize.width - _additionalOffset,
          offset.dy,
        );
        offsetFixed = true;
      }

      // Checking vertical bounds
      if (preferBottom &&
          clickPosition.dy + estimatedSize.height + _additionalOffset >
              MediaQuery.of(context).size.height) {
        debugPrint("Tooltip is too low");
        offset = Offset(
          offset.dx,
          clickPosition.dy - estimatedSize.height - _additionalOffset,
        );
        offsetFixed = true;
      } else if (clickPosition.dy - estimatedSize.height - _additionalOffset <
          0) {
        debugPrint("Tooltip is too high");
        offset = Offset(
          offset.dx,
          clickPosition.dy + estimatedSize.height + _additionalOffset,
        );
        offsetFixed = true;
      }

      if (!offsetFixed) return;

      // Update the position of the tooltip
      entry = OverlayEntry(
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
                  left: offset.dx,
                  top: preferBottom ? offset.dy : null,
                  bottom: preferBottom
                      ? null
                      : MediaQuery.of(context).size.height - offset.dy,
                  child: child,
                ),
              ],
            ),
          );
        },
      );

      if (secondary) {
        _secondaryEntry?.remove();
        _secondaryEntry = entry;
      } else {
        _overlayEntry?.remove();
        _overlayEntry = entry;
      }

      // Insert the overlay
      Overlay.of(context).insert(entry);
    });
  }

  /// Open a context menu with custom builder.
  static void build(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
  }) {
    // Close any existing context menu
    close();

    _closeCompleter = Completer<void>();

    _overlayEntry = OverlayEntry(
      builder: builder,
    );

    // Insert the overlay
    Overlay.of(context).insert(_overlayEntry!);
  }

  static Future<void> waitOnClose() {
    if (_closeCompleter == null || _closeCompleter!.isCompleted) {
      return Future.value();
    }

    return _closeCompleter!.future;
  }

  static void close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _closeCompleter?.complete();
    _closeCompleter = null;
  }

  static void closeSecondary() {
    _secondaryEntry?.remove();
    _secondaryEntry = null;
  }
}
