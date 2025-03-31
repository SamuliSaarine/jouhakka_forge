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

class HoldOrToggle extends ChangeNotifier {
  bool _toggle;
  bool _hold = false;

  HoldOrToggle(bool initialToggle) : _toggle = initialToggle;

  bool get toggled => _toggle;
  bool get holding => _hold;

  void toggle() {
    _toggle = !_toggle;
    notifyListeners();
  }

  void hold() {
    _hold = true;
    notifyListeners();
  }

  void release() {
    _hold = false;
    notifyListeners();
  }

  bool get and => _toggle && _hold;
  bool get or => _toggle || _hold;
  bool get nand => !(_toggle && _hold);
  bool get nor => !(_toggle || _hold);
  bool get xor => _toggle != _hold;
  bool get xnor => _toggle == _hold;
}

class ActionArgument {
  final String name;
  final String value;

  const ActionArgument({required this.name, required this.value});

  ActionArgument.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        value = json['value'] as String;

  static List<ActionArgument> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => ActionArgument.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
