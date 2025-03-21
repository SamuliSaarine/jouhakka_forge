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

  Alignment copy({double? x, double? y}) {
    return Alignment(x ?? this.x, y ?? this.y);
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

extension ColorExtension on Color {
  String _radixFromDouble(double value) {
    int byte = (value * 255).round();
    return byte.toRadixString(16).padLeft(2, '0');
  }

  String toHex() {
    return _radixFromDouble(r) + _radixFromDouble(g) + _radixFromDouble(b);
  }

  int toHexInt() {
    return int.parse('0x${_radixFromDouble(a)}${toHex()}', radix: 16);
  }
}

class ColorWithOpacity extends Color {
  const ColorWithOpacity(int hex, double opacity)
      : assert(opacity >= 0.0 && opacity <= 1.0,
            'Opacity must be between 0.0 and 1.0'),
        super.from(
            alpha: opacity,
            red: ((hex >> 16) & 0xFF) / 255.0,
            green: ((hex >> 8) & 0xFF) / 255.0,
            blue: (hex & 0xFF) / 255.0);
}

extension DoubleExtension on double {
  String toPrecisionOf2() {
    if (this % 1 == 0) return toString();
    if (this % 10 == 0) return toStringAsFixed(1);
    return toStringAsFixed(2);
  }
}
