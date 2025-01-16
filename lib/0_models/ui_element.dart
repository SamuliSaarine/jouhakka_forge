import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
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

  bool expands() =>
      width.type == SizeType.expand || height.type == SizeType.expand;

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

class AxisSize {
  double? value;
  double? minPixels;
  double? maxPixels;
  SizeType type = SizeType.auto;

  AxisSize.fixed(this.value) {
    type = SizeType.fixed;
  }

  AxisSize.auto() {
    type = SizeType.auto;
  }

  AxisSize.expand() {
    type = SizeType.expand;
  }

  AxisSize.flex(this.value) {
    type = SizeType.flex;
  }

  double? tryGetFixed() {
    if (type == SizeType.fixed) {
      return value;
    }
    return null;
  }

  bool constraints() {
    return minPixels != null || maxPixels != null;
  }
}

class PaddingSettings {}
