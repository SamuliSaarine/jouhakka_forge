import 'package:flutter/material.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

class MyTextStyles {
  static const String _fontFamily = 'SometypeMono';
  static bool get _isDark => MyColors.darkMode.value;

  static const FontWeight _bold = FontWeight.w700;
  static const FontWeight _medium = FontWeight.w500;

  static const TextStyle lightTitle = TextStyle(
    fontSize: 20,
    fontFamily: _fontFamily,
    fontWeight: _bold,
    color: MyColors.light,
  );

  static const TextStyle darkTitle = TextStyle(
    fontSize: 18,
    fontFamily: _fontFamily,
    fontWeight: _bold,
    color: MyColors.slate,
  );

  static TextStyle title = _isDark ? darkTitle : lightTitle;

  static const TextStyle header1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: _bold,
    color: MyColors.storm,
  );

  static const TextStyle header2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: _bold,
    color: MyColors.storm,
  );

  static const TextStyle darkHeader3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: _bold,
    color: MyColors.slate,
  );

  static const TextStyle lightHeader3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: _bold,
    color: MyColors.light,
  );

  static TextStyle header3 = _isDark ? darkHeader3 : lightHeader3;

  static const TextStyle lightBody = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: _medium,
    color: MyColors.light,
  );

  static const TextStyle darkBody = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: _medium,
    color: MyColors.dark,
  );

  static const TextStyle stormBody = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: _medium,
    color: MyColors.storm,
  );

  static const TextStyle lightTip = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: _bold,
    fontSize: 14,
    color: MyColors.light,
  );

  static const TextStyle darkTip = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: _bold,
    fontSize: 14,
    color: MyColors.dark,
  );

  static TextStyle tip = _isDark ? darkTip : lightTip;

  static const TextStyle smallTip = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: _bold,
    color: MyColors.storm,
  );
}
