import 'package:flutter/material.dart';

extension AlignmentExtension on Alignment {
  /// All edges are supported, but from corners only bottomRight
  MouseCursor getScaleCursor() {
    switch (this) {
      case Alignment.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case Alignment.topCenter:
      case Alignment.bottomCenter:
        return SystemMouseCursors.resizeUpDown;
      case Alignment.centerLeft:
      case Alignment.centerRight:
        return SystemMouseCursors.resizeLeftRight;
    }
    throw UnimplementedError('MouseCursor for $this is not implemented');
  }

  TextAlign getTextAlignment() {
    switch (this) {
      case Alignment.topLeft:
      case Alignment.centerLeft:
      case Alignment.bottomLeft:
        return TextAlign.left;
      case Alignment.topCenter:
      case Alignment.center:
      case Alignment.bottomCenter:
        return TextAlign.center;
      case Alignment.topRight:
      case Alignment.centerRight:
      case Alignment.bottomRight:
        return TextAlign.right;
    }
    throw UnimplementedError('TextAlign for $this is not implemented');
  }

  double get ratio {
    switch (this) {
      //Vertical edges
      case Alignment.topCenter:
      case Alignment.bottomCenter:
        return 0.5;
      //Corners
      case Alignment.topRight:
      case Alignment.bottomRight:
      case Alignment.bottomLeft:
      case Alignment.topLeft:
        return 1;
      //Horizontal edges
      case Alignment.centerLeft:
      case Alignment.centerRight:
        return 2;
    }
    throw UnimplementedError('Ratio for $this is not implemented');
  }
}
