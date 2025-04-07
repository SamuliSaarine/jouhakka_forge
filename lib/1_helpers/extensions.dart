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

  String toJson() {
    switch (this) {
      case Alignment.topLeft:
        return 'topLeft';
      case Alignment.topCenter:
        return 'topCenter';
      case Alignment.topRight:
        return 'topRight';
      case Alignment.centerLeft:
        return 'centerLeft';
      case Alignment.center:
        return 'center';
      case Alignment.centerRight:
        return 'centerRight';
      case Alignment.bottomLeft:
        return 'bottomLeft';
      case Alignment.bottomCenter:
        return 'bottomCenter';
      case Alignment.bottomRight:
        return 'bottomRight';
    }
    throw UnimplementedError('Alignment for $this is not implemented');
  }

  static Alignment fromString(String? value, {Alignment? defaultValue}) {
    switch (value) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      case null:
        if (defaultValue != null) return defaultValue;
    }
    throw UnimplementedError('Alignment for $value is not implemented');
  }
}

extension FontWeightExtension on FontWeight {
  static FontWeight fromString(String value) {
    value = value.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    switch (value) {
      case 'thin':
        return FontWeight.w100;
      case 'extralight':
        return FontWeight.w200;
      case 'light':
        return FontWeight.w300;
      case 'regular':
      case 'normal':
        return FontWeight.w400;
      case 'medium':
        return FontWeight.w500;
      case 'semibold':
        return FontWeight.w600;
      case 'bold':
        return FontWeight.w700;
      case 'extrabold':
        return FontWeight.w800;
      case 'black':
        return FontWeight.w900;
    }
    return FontWeight.w500;
  }

  String toJson() {
    switch (this) {
      case FontWeight.w100:
        return 'thin';
      case FontWeight.w200:
        return 'extraLight';
      case FontWeight.w300:
        return 'light';
      case FontWeight.w400:
        return 'normal';
      case FontWeight.w500:
        return 'medium';
      case FontWeight.w600:
        return 'semiBold';
      case FontWeight.w700:
        return 'bold';
      case FontWeight.w800:
        return 'extraBold';
      case FontWeight.w900:
        return 'black';
    }
    throw UnimplementedError('FontWeight for $this is not implemented');
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

  static Color fromHex(String input) {
    String hex = input.replaceFirst('#', '');
    if (hex.length == 1) {
      hex = hex * 6; // Expand single digit hex to full form
    } else if (hex.length == 2) {
      hex = hex * 3; // Expand double digit hex to full form
    } else if (hex.length == 3) {
      hex =
          hex.split('').map((char) => char * 2).join(); // Expand shorthand hex
    } else if (hex.length == 4) {
      hex = hex
          .split('')
          .map((char) => char * 2)
          .join(); // Expand shorthand hex with alpha
    }

    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha value if not provided
    } else if (hex.length == 8) {
      // Convert from RRGGBBAA to AARRGGBB format
      String alpha = hex.substring(6, 8);
      String rgb = hex.substring(0, 6);
      hex = alpha + rgb;
    }

    return Color(int.parse(hex, radix: 16));
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
