import 'package:flutter/material.dart';

class MyColors {
  static ValueNotifier<bool> darkMode = ValueNotifier(false);
  static bool get _isDark => darkMode.value;

  static const Color light = Color.fromARGB(255, 250, 250, 250);
  static const Color lightGray = Color.fromARGB(255, 233, 255, 250);
  static const Color semilightGray = Color.fromARGB(255, 220, 220, 220);
  static const Color dark = Color.fromARGB(255, 25, 27, 29);

  static const Color darkerCharcoal = Color.fromARGB(255, 34, 43, 47);
  static const Color lighterCharcoal = Color.fromARGB(255, 66, 88, 96);

  static const Color mint = Color.fromARGB(255, 0, 184, 148);
  static const Color lightMint = Color.fromARGB(255, 243, 248, 248);
  static const Color mintgray = Color.fromARGB(255, 228, 238, 233);

  static const Color lighterBlue = Color.fromARGB(255, 23, 142, 211);
  static const Color darkerBlue = Color.fromARGB(255, 0, 122, 184);

  static const Color mildDifference = Color.fromRGBO(128, 128, 128, 0.1);
  static const Color mediumDifference = Color.fromRGBO(128, 128, 128, 0.2);
  static const Color strongDifference = Color.fromRGBO(128, 128, 128, 0.3);

  static Color get charcoal => _isDark ? lighterCharcoal : darkerCharcoal;

  static Color get mintOrCoal => _isDark ? darkerCharcoal : mintgray;

  static Color get background => _isDark ? dark : light;

  static Color get blue => _isDark ? darkerBlue : lighterBlue;

  static Color get text => _isDark ? Colors.white : Colors.black;
}
