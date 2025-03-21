import 'package:flutter/material.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';

class MyColors {
  static ValueNotifier<bool> darkMode = ValueNotifier(false);
  static bool get _isDark => darkMode.value;

  static const int _light = 0xFFFAFAFA;
  static const Color light = Color(_light);
  static const ColorWithOpacity light75 = ColorWithOpacity(_light, 0.75);
  static const ColorWithOpacity light25 = ColorWithOpacity(_light, 0.25);

  static const int _dark = 0xFF191B1D;
  static const Color dark = Color(_dark);
  static const ColorWithOpacity dark60 = ColorWithOpacity(_dark, 0.6);
  static const ColorWithOpacity dark40 = ColorWithOpacity(_dark, 0.4);

  static const int _slateHex = 0xFF27353C;
  static const Color slate = Color(_slateHex);
  static const Color slate80 = ColorWithOpacity(_slateHex, 0.8);
  static const Color slate60 = ColorWithOpacity(_slateHex, 0.6);

  static const int _stormHex = 0xFF67797D;
  static const Color storm = Color(_stormHex);
  static const Color storm50 = ColorWithOpacity(_stormHex, 0.5);
  static const Color storm30 = ColorWithOpacity(_stormHex, 0.3);
  static const Color storm12 = ColorWithOpacity(_stormHex, 0.12);

  static const int _lightMint = 0xFF00FFB7;
  static const int _darkMint = 0xFF1CD19E;
  static const Color lightMint = Color(_lightMint);
  static const Color darkMint = Color(_darkMint);
  static const Color mintgray = Color(0xFF8EC2B3);

  static const Color lighterBlue = Color.fromARGB(255, 23, 142, 211);
  static const Color darkerBlue = Color.fromARGB(255, 0, 122, 184);

  static const Color mildDifference = Color.fromRGBO(128, 128, 128, 0.1);
  static const Color mediumDifference = Color.fromRGBO(128, 128, 128, 0.2);
  static const Color strongDifference = Color.fromRGBO(128, 128, 128, 0.3);

  static Color get charcoal => _isDark ? storm : slate;

  static Color get mintOrCoal => _isDark ? slate : mintgray;

  static Color get background => _isDark ? dark : light;

  static Color get blue => _isDark ? darkerBlue : lighterBlue;

  static Color get text => _isDark ? Colors.white : Colors.black;
}
