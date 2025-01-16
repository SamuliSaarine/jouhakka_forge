import 'package:flutter/material.dart';

class Resolution {
  final double width;
  final double height;
  final double ratio;

  const Resolution({required this.width, required this.height})
      : ratio = width / height;

  static const Resolution fullHD = Resolution(width: 1920, height: 1080);

  static const Resolution ipad10 = Resolution(width: 820, height: 1180);

  static const Resolution iphone13 = Resolution(width: 390, height: 844);

  @override
  operator ==(Object other) {
    if (other is Resolution) {
      return width == other.width && height == other.height;
    }
    return false;
  }

  operator +(Size size) {
    return Resolution(width: width + size.width, height: height + size.height);
  }

  operator -(Size size) {
    return Resolution(width: width - size.width, height: height - size.height);
  }

  @override
  int get hashCode => width.hashCode + 100000 * height.hashCode;
}
