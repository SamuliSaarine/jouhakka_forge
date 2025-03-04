import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';

/// - `constant`: Value is set in the [UIElement] itself.s
/// - `root`: Value is binded to a variable in [ElementRoot].
/// - `global`: Value is binded to a global variable.
enum ValueSource { constant, root, global, composite }

//EV = Element Value (Using short name because it's used a lot)
class EV<T> extends ChangeNotifier {
  String? label;
  T _value;
  String? variableKey;
  ValueSource source;

  /// This class allows binding properties to variables.
  EV(T value,
      {this.label, this.variableKey, this.source = ValueSource.constant})
      : _value = value;

  bool setRootVariable(ElementRoot root, String key) {
    try {
      T value = root.getVariable<T>(key);

      variableKey = key;
      source = ValueSource.root;
      _value = value;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  void setGlobalVariable(String key) {
    variableKey = key;
    source = ValueSource.global;
    notifyListeners();
  }

  void setConstantValue(T value) {
    _value = value;
    source = ValueSource.constant;
    variableKey = null;
    notifyListeners();
  }

  T get value => _value;

  set value(T value) {
    _value = value;
    source = ValueSource.constant;
  }

  void copy(EV<T> other) {
    label = other.label;
    _value = other.value;
    variableKey = other.variableKey;
    source = other.source;
    notifyListeners();
  }
}

class CompositeEV<T> extends EV<T> {
  //TODO: Implement composite value
  CompositeEV(EV<T> value) : super(value.value, source: ValueSource.composite) {
    source = ValueSource.composite;
  }
}

enum SizeType { fixed, expand, flex, auto }

class AxisSize extends ChangeNotifier {
  //Size in the axis in pixels. If the type is not fixed, and ElementWidget of UIElement is not built, this value is null.
  double? _value;
  double? get value => _value;
  set value(double? value) {
    _value = value;
    notifyListeners();
  }

  int? _flex;
  double? _minPixels;
  double? _maxPixels;
  SizeType _type = SizeType.expand;
  Function()? valueListener;

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

  /// Set [UIElement] size in axis to a fixed pixel value.
  void fixed(double value) {
    _value = value;
    type = SizeType.fixed;
    notifyListeners();
    double.infinity;
  }

  void add(double value) {
    if (_type != SizeType.fixed) {
      _type = SizeType.fixed;
      _value ??= 8;
    }
    _value = _value! + value;
    notifyListeners();
  }

  void multiply(double value) {
    if (_type != SizeType.fixed) {
      _type = SizeType.fixed;
      _value ??= 8;
    }

    _value = _value! * clampDouble(1 + value / 10, 0, 2);
    notifyListeners();
  }

  /// Allow [UIElement] size in axis to decide its own size.
  ///
  /// If [UIElement] has no content, or it's content has no minimum size in the axis, the [AxisSize] will act like [AxisSize.expand]
  ///
  /// If the [UIElement] has content that has minimum size in the axis, the [UIElement] will try to be as small as the content allows.
  /// - `minPixels` will limit how small the [UIElement] can be.
  /// - `maxPixels` will limit how big the [UIElement] can be.
  ///   - If the content is bigger than `maxPixels`, the content will overflow.
  void auto({double? minPixels, double? maxPixels}) {
    _type = SizeType.auto;
    _minPixels = minPixels;
    _maxPixels = maxPixels;
    notifyListeners();
  }

  /// [UIElement] tries to fill all the available space in the axis.
  /// - `maxPixels` will limit how far the [UIElement] can expand.
  /// - `minPixels` will allow [UIElement] to request more space from it's parent, if it's not getting enough.
  ///   - Will either steal space from expanding siblings or overflow
  /// - `flex` will determine how much space the [UIElement] will take compared to other [UIElement]s with the same parent.
  ///   - For example, if there are two [UIElement]s with `flex: 1` and `flex: 3`,
  ///     the first [UIElement] will take 1/4 of the available space and the second [UIElement] will take 3/4 of the available space.
  void expand({double? minPixels, double? maxPixels, int? flex}) {
    _type = SizeType.expand;
    _minPixels = minPixels;
    _maxPixels = maxPixels;
    _flex = flex;
    notifyListeners();
  }

  void copy(AxisSize other) {
    _value = other.value;
    _flex = other._flex;
    _minPixels = other._minPixels;
    _maxPixels = other._maxPixels;
    _type = other._type;
    notifyListeners();
  }

  /// Retuns [UIElement] size in the axis, if the type is fixed.
  ///
  /// Otherwise returns `null`.
  double? tryGetFixed() {
    if (_type == SizeType.fixed) {
      return value;
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
        return value.toString();
      case SizeType.expand:
        return "Expand (${value.toString()}), [${_minPixels.toString()} - ${_maxPixels.toString()}]";
      case SizeType.flex:
        return "Flex: $_flex (${value.toString()}), [${_minPixels.toString()} - ${_maxPixels.toString()}]";
      case SizeType.auto:
        return "Auto (${value.toString()}), [${_minPixels.toString()} - ${_maxPixels.toString()}]";
    }
  }
}

class OptionalProperty<T> {
  T? _value;
  final Function() listener;
  T? get value => _value;
  ValueNotifier<bool> hasValueNotifier = ValueNotifier(false);
  set value(T? value) {
    if (value == _value) return;
    dispose();
    _value = value;
    hasValueNotifier.value = value != null;
    forwardListener();
    listener();
  }

  OptionalProperty(
    T? value, {
    required this.listener,
  }) : _value = value {
    hasValueNotifier.value = value != null;
    forwardListener();
  }

  void forwardListener() {
    if (_value is ChangeNotifier) {
      (_value as ChangeNotifier).addListener(listener);
    }
  }

  void dispose() {
    if (_value is ChangeNotifier) {
      (_value as ChangeNotifier).removeListener(listener);
    }
  }

  bool ifValue(void Function(T) callback, {void Function()? orElse}) {
    if (_value != null) {
      try {
        callback(_value as T);
        return true;
      } catch (e, s) {
        debugPrint("Error in OptionalProperty<$T>.ifValue: $e | $s");
      }
    }
    orElse?.call();
    return false;
  }
}
