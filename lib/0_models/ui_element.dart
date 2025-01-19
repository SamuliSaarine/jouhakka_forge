import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';

class UIElement {
  final ElementRoot root;
  final String id;
  UIElement? parent;
  AxisSize width = AxisSize.expand();
  AxisSize height = AxisSize.expand();
  EdgeInsetsGeometry? padding;
  ElementDecoration? decoration;

  UIElement({required this.root, required this.parent})
      : id = IDService.newElementID(root.id);

  factory UIElement.defaultBox(ElementRoot root, {UIElement? parent}) {
    UIElement element = UIElement(root: root, parent: parent);
    element.padding = const EdgeInsets.all(8);
    element.decoration = ElementDecoration()
      ..setBackgroundColor(Colors.white)
      ..setBorderColor(Colors.black)
      ..setBorderWidth(1);
    return element;
  }

  factory UIElement.empty(ElementRoot root, UIElement? parent) {
    return UIElement(root: root, parent: parent);
  }

  Widget? getContent() {
    return null;
  }

  Widget? getContentAsWireframe() {
    return null;
  }

  Resolution? getResolution() {
    if (width.value == null || height.value == null) return null;
    return Resolution(width: width.value!, height: height.value!);
  }

  bool expands({Axis? axis}) {
    if (axis == null) {
      return width.type == SizeType.expand || height.type == SizeType.expand;
    } else if (axis == Axis.horizontal) {
      return width.type == SizeType.expand;
    } else {
      return height.type == SizeType.expand;
    }
  }

  static UIElement fromType(
      UIElementType type, ElementRoot root, UIElement? parent) {
    switch (type) {
      case UIElementType.empty:
        return UIElement.empty(root, parent);
      case UIElementType.box:
        return UIElement.defaultBox(root, parent: parent);
      case UIElementType.text:
        return TextElement(root: root, parent: parent);
      case UIElementType.image:
        return ImageElement(root: root, parent: parent);
    }
  }
}

enum ValueSource { constant, parent, global }

class EV<T> {
  String? label;
  T? _value;
  String? variableKey;
  ValueSource source;

  EV({this.label, T? value}) : source = ValueSource.constant {
    _value = value;
  }

  void setParentVariable(String key) {
    variableKey = key;
    source = ValueSource.parent;
  }

  void setGlobalVariable(String key) {
    variableKey = key;
    source = ValueSource.global;
  }

  T? get value {
    switch (source) {
      case ValueSource.constant:
        return _value;
      case ValueSource.parent:
        return null;
      case ValueSource.global:
        return null;
    }
  }

  set value(T? value) {
    _value = value;
    source = ValueSource.constant;
  }

  T promiseValue(T defaultValue) {
    return value ?? defaultValue;
  }
}

class ElementDecoration {
  EV<int> backgroundColorHex = EV();
  EV<double> radius = EV();
  EV<double> borderWidth = EV();
  EV<int> borderColorHex = EV();
  EdgeInsetsGeometry? margin;

  ElementDecoration(
      {int? backgroundColor,
      double? radius,
      double? borderWidth,
      int? borderColor}) {
    if (backgroundColor != null) {
      backgroundColorHex.value = backgroundColor;
    }
    if (radius != null) {
      this.radius.value = radius;
    }
    if (borderWidth != null) {
      this.borderWidth.value = borderWidth;
    }
    if (borderColor != null) {
      borderColorHex.value = borderColor;
    }
  }

  Color? getBackgroundColor() {
    if (backgroundColorHex.value != null) {
      return Color(backgroundColorHex.value!);
    }
    return null;
  }

  void setBackgroundColor(Color? color) {
    if (color != null) {
      backgroundColorHex.value = color.value;
    }
  }

  Color getBorderColor() {
    if (borderColorHex.value != null) {
      return Color(borderColorHex.value!);
    }
    return Colors.black;
  }

  void setBorderColor(Color? color) {
    borderColorHex.value = color?.value;
  }

  double getBorderWidth() {
    return borderWidth.value ?? 0;
  }

  void setBorderWidth(double? width) {
    borderWidth.value = width;
  }

  double getRadius() {
    return radius.value ?? 0;
  }

  void setRadius(double? r) {
    radius.value = r;
  }
}

enum SizeType { fixed, expand, flex, auto }

class AxisSize extends ChangeNotifier {
  double? _value;
  int? _flex;
  double? _minPixels;
  double? _maxPixels;
  SizeType _type = SizeType.auto;

  double? get value => _value;
  set value(double? value) {
    _value = value;
    notifyListeners();
  }

  int? get flex => _flex;
  set flex(int? flex) {
    _flex = flex;
    notifyListeners();
  }

  double? get minPixels => _minPixels;
  set minPixels(double? minPixels) {
    _minPixels = minPixels;
    notifyListeners();
  }

  double? get maxPixels => _maxPixels;
  set maxPixels(double? maxPixels) {
    _maxPixels = maxPixels;
    notifyListeners();
  }

  SizeType get type => _type;
  set type(SizeType type) {
    _type = type;
    notifyListeners();
  }

  AxisSize.fixed(this._value) {
    type = SizeType.fixed;
  }

  AxisSize.auto({double? minPixels, double? maxPixels})
      : _type = SizeType.auto,
        _minPixels = minPixels,
        _maxPixels = maxPixels;

  AxisSize.expand({double? minPixels, double? maxPixels})
      : _type = SizeType.expand,
        _minPixels = minPixels,
        _maxPixels = maxPixels;

  AxisSize.flex(int? flex)
      : _type = SizeType.flex,
        _flex = flex;

  double? tryGetFixed() {
    if (_type == SizeType.fixed) {
      return _value;
    }
    return null;
  }

  bool constraints() {
    return _minPixels != null || _maxPixels != null;
  }

  @override
  String toString() {
    switch (_type) {
      case SizeType.fixed:
        return _value.toString();
      case SizeType.expand:
        return "Expand (${_value.toString()}), [${_minPixels.toString()} - ${_maxPixels.toString()}]";
      case SizeType.flex:
        return "Flex: $_flex (${_value.toString()}), [${_minPixels.toString()} - ${_maxPixels.toString()}]";
      case SizeType.auto:
        return "Auto (${_value.toString()}), [${_minPixels.toString()} - ${_maxPixels.toString()}]";
    }
  }
}

class PaddingSettings {}
