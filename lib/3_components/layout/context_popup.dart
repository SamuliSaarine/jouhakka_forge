import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';

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
    Alignment preferAlignment = Alignment.topLeft,
  }) {
    // Close any existing context menu
    if (secondary) {
      closeSecondary();
    } else {
      bool tryNextFrame = _overlayEntry != null;
      close();
      if (tryNextFrame) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          open(
            context,
            clickPosition: clickPosition,
            child: child,
            secondary: secondary,
            preferAlignment: preferAlignment,
          );
        });
        return;
      }
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
                left: _calculateLeftPosition(
                    context, clickPosition, preferAlignment),
                right: _calculateRightPosition(
                    context, clickPosition, preferAlignment),
                top: _calculateTopPosition(
                    context, clickPosition, preferAlignment),
                bottom: _calculateBottomPosition(
                    context, clickPosition, preferAlignment),
                child: Align(
                  alignment: preferAlignment,
                  child: SizedBox(
                    key: tooltipKey,
                    child: child,
                  ),
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

    debugPrint("Entry is mounted: ${entry.mounted}");

    // Post frame callback to calculate the position of the tooltip
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        debugPrint("Calculate key: $tooltipKey");
        final RenderBox? renderBox =
            tooltipKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          debugPrint("Render box is null. Entry is mounted: ${entry.mounted}");
          return;
        }
        final estimatedSize = renderBox.size;
        debugPrint("Estimated size: $estimatedSize");

        Alignment alignment = preferAlignment;

        // Checking horizontal bounds
        if (preferAlignment.x == 1) {
          if (clickPosition.dx - estimatedSize.width - _additionalOffset < 0) {
            debugPrint("Tooltip is too far left");
            alignment = preferAlignment.copy(x: -1);
          }
        } else if (preferAlignment.x == -1) {
          if (clickPosition.dx + estimatedSize.width + _additionalOffset >
              MediaQuery.of(context).size.width) {
            debugPrint("Tooltip is too far right");
            alignment = alignment.copy(x: 1);
          }
        } else if (preferAlignment.x == 0) {
          if (clickPosition.dx + estimatedSize.width / 2 + _additionalOffset >
              MediaQuery.of(context).size.width) {
            debugPrint("Tooltip is too far right");
            alignment = alignment.copy(x: 1);
          } else if (clickPosition.dx - estimatedSize.width / 2 < 0) {
            debugPrint("Tooltip is too far left");
            alignment = alignment.copy(x: -1);
          }
        }

        // Checking vertical bounds
        if (alignment.y == 1) {
          if (clickPosition.dy - estimatedSize.height - _additionalOffset < 0) {
            debugPrint("Tooltip is too high");
            alignment = alignment.copy(y: -1);
          }
        } else if (alignment.y == -1) {
          if (clickPosition.dy + estimatedSize.height + _additionalOffset >
              MediaQuery.of(context).size.height) {
            debugPrint("Tooltip is too low");
            alignment = alignment.copy(y: 1);
          }
        } else if (preferAlignment.y == 0) {
          if (clickPosition.dy + estimatedSize.height / 2 + _additionalOffset >
              MediaQuery.of(context).size.height) {
            debugPrint("Tooltip is too low");
            alignment = alignment.copy(y: 1);
          } else if (clickPosition.dy - estimatedSize.height / 2 < 0) {
            debugPrint("Tooltip is too high");
            alignment = alignment.copy(y: -1);
          }
        }

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
                    left: _calculateLeftPosition(
                        context, clickPosition, alignment),
                    right: _calculateRightPosition(
                        context, clickPosition, alignment),
                    top: _calculateTopPosition(
                        context, clickPosition, alignment),
                    bottom: _calculateBottomPosition(
                        context, clickPosition, alignment),
                    child: Align(
                      alignment: alignment,
                      child: SizedBox(
                        key: tooltipKey,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (secondary) {
          _secondaryEntry?.remove();
          _secondaryEntry?.dispose();
          _secondaryEntry = entry;
        } else {
          _overlayEntry?.remove();
          _overlayEntry?.dispose();
          _overlayEntry = entry;
        }

        // Insert the overlay
        Overlay.of(context).insert(entry);
      },
    );
  }

  static double? _calculateLeftPosition(
      BuildContext context, Offset clickPosition, Alignment alignment) {
    if (alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft ||
        alignment == Alignment.centerLeft) {
      return clickPosition.dx + _additionalOffset;
    } else if (alignment == Alignment.center ||
        alignment == Alignment.topCenter ||
        alignment == Alignment.bottomCenter) {
      return 2 * clickPosition.dx - MediaQuery.of(context).size.width;
    }
    return null;
  }

  static double? _calculateRightPosition(
      BuildContext context, Offset clickPosition, Alignment alignment) {
    if (alignment == Alignment.topRight ||
        alignment == Alignment.bottomRight ||
        alignment == Alignment.centerRight) {
      return MediaQuery.of(context).size.width -
          clickPosition.dx -
          _additionalOffset;
    } else if (alignment == Alignment.center ||
        alignment == Alignment.topCenter ||
        alignment == Alignment.bottomCenter) {
      return MediaQuery.of(context).size.width - clickPosition.dx * 2;
    }
    return null;
  }

  static double? _calculateTopPosition(
      BuildContext context, Offset clickPosition, Alignment alignment) {
    if (alignment == Alignment.topLeft ||
        alignment == Alignment.topRight ||
        alignment == Alignment.topCenter) {
      return clickPosition.dy + _additionalOffset;
    } else if (alignment == Alignment.center ||
        alignment == Alignment.centerLeft ||
        alignment == Alignment.centerRight) {
      return 2 * clickPosition.dy - MediaQuery.of(context).size.height;
    }
    return null;
  }

  static double? _calculateBottomPosition(
      BuildContext context, Offset clickPosition, Alignment alignment) {
    if (alignment == Alignment.bottomLeft ||
        alignment == Alignment.bottomRight ||
        alignment == Alignment.bottomCenter) {
      return MediaQuery.of(context).size.height -
          clickPosition.dy -
          _additionalOffset;
    } else if (alignment == Alignment.center ||
        alignment == Alignment.centerLeft ||
        alignment == Alignment.centerRight) {
      return MediaQuery.of(context).size.height - clickPosition.dy * 2;
    }
    return null;
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
