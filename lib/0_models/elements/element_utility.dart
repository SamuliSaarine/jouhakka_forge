import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';

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
      //T value = root.getVariable<T>(key);

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

  EV.from(EV<T> other)
      : _value = other.value,
        label = other.label,
        variableKey = other.variableKey,
        source = other.source;

  bool equals(EV<T> other) {
    return _value == other.value &&
        label == other.label &&
        variableKey == other.variableKey &&
        source == other.source;
  }
}

abstract class AxisSize {
  double? get renderValue;

  AxisSize clone();
}

class ControlledSize extends AxisSize {
  final Variable<double> value;

  ControlledSize(this.value);

  ControlledSize.constant(double value) : value = ConstantVariable(value);

  @override
  AxisSize clone() {
    return ControlledSize(value);
  }

  @override
  double get renderValue => value.value;
}

abstract class AutomaticSize extends AxisSize {
  final Variable<double> min;
  final Variable<double> max;

  bool get constrained => min.value > 0 || max.value < double.infinity;

  AutomaticSize({
    Variable<double>? min,
    Variable<double>? max,
  })  : min = min ?? ConstantVariable(0),
        max = max ?? ConstantVariable(double.infinity);

  @override
  double? renderValue;

  @override
  AutomaticSize clone({Variable<double>? min, Variable<double>? max});
}

class ShrinkingSize extends AutomaticSize {
  ShrinkingSize({super.min, super.max});

  ShrinkingSize.constant(double min, double max)
      : super(min: ConstantVariable(min), max: ConstantVariable(max));

  ShrinkingSize.from(AutomaticSize size)
      : super(min: size.min.clone(), max: size.max);

  @override
  ShrinkingSize clone({Variable<double>? min, Variable<double>? max}) {
    return ShrinkingSize(
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }
}

class ExpandingSize extends AutomaticSize {
  final Variable<int> flex;

  ExpandingSize({
    super.min,
    super.max,
    Variable<int>? flex,
  }) : flex = flex ?? ConstantVariable(1);

  ExpandingSize.constant(double min, double max, int flex)
      : flex = ConstantVariable(flex),
        super(min: ConstantVariable(min), max: ConstantVariable(max));

  ExpandingSize.from(AutomaticSize size)
      : flex = ConstantVariable(1),
        super(min: size.min, max: size.max);

  @override
  ExpandingSize clone(
      {Variable<double>? min, Variable<double>? max, Variable<int>? flex}) {
    return ExpandingSize(
      min: min ?? this.min,
      max: max ?? this.max,
      flex: flex ?? this.flex,
    );
  }
}

class SizeHolder extends ChangeNotifier {
  AxisSize _width;
  AxisSize _height;

  double get promiseWidth => _width.renderValue!;
  double get promiseHeight => _height.renderValue!;

  double? get constantWidth =>
      _width is ControlledSize ? _width.renderValue : null;
  double? get constantHeight =>
      _height is ControlledSize ? _height.renderValue : null;

  set width(AxisSize width) {
    _width = width;
    notifyListeners();
  }

  set height(AxisSize height) {
    _height = height;
    notifyListeners();
  }

  void widthToConstant() {
    width = ControlledSize.constant(_width.renderValue!);
  }

  void heightToConstant() {
    height = ControlledSize.constant(_height.renderValue!);
  }

  AxisSize get width => _width;
  AxisSize get height => _height;

  SizeHolder(
    AxisSize width,
    AxisSize height,
  )   : _width = width,
        _height = height;

  factory SizeHolder.constant(double width, double height) {
    return SizeHolder(
      ControlledSize.constant(width),
      ControlledSize.constant(height),
    );
  }

  factory SizeHolder.auto() {
    return SizeHolder(
      ShrinkingSize(),
      ShrinkingSize(),
    );
  }

  factory SizeHolder.expand() {
    return SizeHolder(
      ExpandingSize(),
      ExpandingSize(),
    );
  }

  AxisSize getAxis(Axis axis) {
    return axis == Axis.horizontal ? _width : _height;
  }

  /// Combines the `width` and `height` settings to a [Resolution] object.
  ///
  /// Returns `null` if either `width` or `height` value cannot be resolved.
  Resolution? getResolution() {
    if (width.renderValue == null || height.renderValue == null) return null;
    return Resolution(width: width.renderValue!, height: height.renderValue!);
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  /// If `axis` is not specified, returns `true` if either `width` or `height` expands.
  ///
  /// If `axis` is specified, returns `true` if the specified `axis` expands.
  bool expands({Axis? axis}) {
    if (axis == null) {
      return width is ExpandingSize || height is ExpandingSize;
    } else if (axis == Axis.horizontal) {
      return width is ExpandingSize;
    } else {
      return height is ExpandingSize;
    }
  }

  bool shrinks({Axis? axis}) {
    if (axis == null) {
      return width is ShrinkingSize || height is ShrinkingSize;
    } else if (axis == Axis.horizontal) {
      return width is ShrinkingSize;
    } else {
      return height is ShrinkingSize;
    }
  }

  bool isConstrained() {
    return (width is AutomaticSize && (width as AutomaticSize).constrained) ||
        (height is AutomaticSize && (height as AutomaticSize).constrained);
  }

  void copy(SizeHolder other) {
    _width = other.width;
    _height = other.height;
    notifyListeners();
  }

  void addWidth(double value) {
    width = ControlledSize.constant((_width.renderValue ?? 0) + value);
    notifyListeners();
  }

  void addHeight(double value) {
    height = ControlledSize.constant((_height.renderValue ?? 0) + value);
    notifyListeners();
  }
}

enum SizeType { fixed, expand, flex, auto }

class AxisSizeOld extends ChangeNotifier {
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
  /// If [UIElement] has no content, or it's content has no minimum size in the axis, the [AxisSizeOld] will act like [AxisSizeOld.expand]
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

  void copy(AxisSizeOld other) {
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

//Handles tracking existence of a value and disposing and forwarding listeners to the value
class OptionalProperty<T> {
  T? _value;
  final Function() listener;
  T? get value => _value;
  final ValueNotifier<bool> hasValueNotifier;
  set value(T? value) {
    if (value == _value) {
      //debugPrint("[$hashCode] OptionalProperty<$T>.value: Value is the same, not updating");
      return;
    }
    //debugPrint("[$hashCode] OptionalProperty<$T>.value: Replace value $_value(${_value?.hashCode}) with $value(${value?.hashCode})");
    T? oldValue = _value;
    //dispose();

    _value = value;
    forwardListener();
    hasValueNotifier.value = value != null;
    //debugPrint("[$hashCode] Called hasValueNotifier.value = $value != null = ${value != null}");
    listener();
    if (oldValue is ChangeNotifier) {
      //debugPrint("[$hashCode] OptionalProperty<$T>.value: Removing listener from $oldValue");
      (oldValue as ChangeNotifier).removeListener(listener);
      (oldValue as ChangeNotifier).dispose();
      //debugPrint("[$hashCode] OptionalProperty<$T>.value: Disposed old value");
    }
  }

  OptionalProperty(
    T? value, {
    required this.listener,
  })  : _value = value,
        hasValueNotifier = ValueNotifier(value != null) {
    forwardListener();
    //debugPrint("[$hashCode] Constructed OptionalProperty<$T> with value $value. HasValueNotifier: ${hasValueNotifier.value}");
  }

  void forwardListener() {
    if (_value is ChangeNotifier) {
      //debugPrint("[$hashCode] OptionalProperty<$T>.forwardListener: Forwarding listener to $_value");
      (_value as ChangeNotifier).addListener(listener);
    }
  }

  void dispose() {
    if (_value is ChangeNotifier) {
      ChangeNotifier notifier = _value as ChangeNotifier;
      _value = null;
      notifier.dispose();
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

class MyRadius {
  final Variable<double> topLeft;
  final Variable<double> topRight;
  final Variable<double> bottomRight;
  final Variable<double> bottomLeft;

  MyRadius({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  MyRadius.all(Variable<double> radius)
      : topLeft = radius,
        topRight = radius,
        bottomRight = radius,
        bottomLeft = radius;

  MyRadius.constant(
      double topleft, double topright, double bottomright, double bottomleft)
      : topLeft = ConstantVariable(topleft),
        topRight = ConstantVariable(topright),
        bottomRight = ConstantVariable(bottomright),
        bottomLeft = ConstantVariable(bottomleft);

  factory MyRadius.constantAll(double radius) =>
      MyRadius.constant(radius, radius, radius, radius);

  MyRadius clone(void Function() notifyListeners) {
    if (topLeft is ConstantVariable &&
        topRight is ConstantVariable &&
        bottomRight is ConstantVariable &&
        bottomLeft is ConstantVariable) {
      return this;
    }
    return MyRadius(
      topLeft: topLeft.clone(notifyListeners: notifyListeners),
      topRight: topRight.clone(notifyListeners: notifyListeners),
      bottomRight: bottomRight.clone(notifyListeners: notifyListeners),
      bottomLeft: bottomLeft.clone(notifyListeners: notifyListeners),
    );
  }

  BorderRadius get borderRadius {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft.value),
      topRight: Radius.circular(topRight.value),
      bottomRight: Radius.circular(bottomRight.value),
      bottomLeft: Radius.circular(bottomLeft.value),
    );
  }

  bool equals(MyRadius other) {
    return topLeft.value == other.topLeft.value &&
        topRight.value == other.topRight.value &&
        bottomRight.value == other.bottomRight.value &&
        bottomLeft.value == other.bottomLeft.value;
  }
}

class MyPadding {
  final Variable<double> top;
  final Variable<double> bottom;
  final Variable<double> left;
  final Variable<double> right;

  const MyPadding({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  MyPadding.all(Variable<double> value)
      : top = value,
        bottom = value,
        left = value,
        right = value;

  MyPadding.constant(double top, double bottom, double left, double right)
      : top = ConstantVariable(top),
        bottom = ConstantVariable(bottom),
        left = ConstantVariable(left),
        right = ConstantVariable(right);

  factory MyPadding.constantAll(double value) =>
      MyPadding.constant(value, value, value, value);

  static const MyPadding zero = MyPadding(
      top: ConstantVariable(0),
      bottom: ConstantVariable(0),
      left: ConstantVariable(0),
      right: ConstantVariable(0));

  MyPadding clone(void Function() notifyListeners) {
    if (top is ConstantVariable &&
        bottom is ConstantVariable &&
        left is ConstantVariable &&
        right is ConstantVariable) {
      return this;
    }
    return MyPadding(
      top: top.clone(notifyListeners: notifyListeners),
      bottom: bottom.clone(notifyListeners: notifyListeners),
      left: left.clone(notifyListeners: notifyListeners),
      right: right.clone(notifyListeners: notifyListeners),
    );
  }

  EdgeInsets get padding {
    return EdgeInsets.only(
      top: top.value,
      bottom: bottom.value,
      left: left.value,
      right: right.value,
    );
  }

  bool equals(MyRadius other) {
    return top.value == other.topLeft.value &&
        bottom.value == other.topRight.value &&
        left.value == other.bottomRight.value &&
        right.value == other.bottomLeft.value;
  }
}

class MyBorder extends ChangeNotifier {
  final MyBorderSide top;
  final MyBorderSide right;
  final MyBorderSide bottom;
  final MyBorderSide left;

  MyBorder({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  }) {
    top.addListener(notifyListeners);
    right.addListener(notifyListeners);
    bottom.addListener(notifyListeners);
    left.addListener(notifyListeners);
  }

  factory MyBorder.all(Color color, double width) => MyBorder(
      top: MyBorderSide(color, width),
      right: MyBorderSide(color, width),
      bottom: MyBorderSide(color, width),
      left: MyBorderSide(color, width));

  @override
  void dispose() {
    top.removeListener(notifyListeners);
    right.removeListener(notifyListeners);
    bottom.removeListener(notifyListeners);
    left.removeListener(notifyListeners);

    //debugPrint("MyBorder.dispose: Disposing sides");
    top.dispose();
    right.dispose();
    bottom.dispose();
    left.dispose();
    super.dispose();
  }

  static MyBorder get defaultBorder => MyBorder.all(Colors.black, 1);

  bool get isConstant =>
      top.isConstant &&
      right.isConstant &&
      bottom.isConstant &&
      left.isConstant;

  MyBorder clone() {
    return MyBorder(
      top: MyBorderSide.from(top),
      right: MyBorderSide.from(right),
      bottom: MyBorderSide.from(bottom),
      left: MyBorderSide.from(left),
    );
  }

  Border get boxBorder {
    return Border(
      top: top.enabled
          ? BorderSide(color: top.color.value, width: top.width.value)
          : BorderSide.none,
      right: right.enabled
          ? BorderSide(color: right.color.value, width: right.width.value)
          : BorderSide.none,
      bottom: bottom.enabled
          ? BorderSide(color: bottom.color.value, width: bottom.width.value)
          : BorderSide.none,
      left: left.enabled
          ? BorderSide(color: left.color.value, width: left.width.value)
          : BorderSide.none,
    );
  }

  bool get equalSides {
    return top.equals(right) && right.equals(bottom) && bottom.equals(left);
  }

  bool equals(MyBorder other) {
    return top.equals(other.top) &&
        right.equals(other.right) &&
        bottom.equals(other.bottom) &&
        left.equals(other.left);
  }
}

class MyBorderSide extends ChangeNotifier {
  final VarField<Color> color;
  final VarField<double> width;

  bool get enabled => color.value != Colors.transparent && width.value > 0;
  bool get isConstant =>
      color.variable is ConstantVariable && width.variable is ConstantVariable;

  void copy(MyBorderSide other) {
    color.copy(other.color);
    width.copy(other.width);
  }

  MyBorderSide(Color color, double width)
      : color = VarField.constant(color),
        width = VarField.constant(width) {
    this.color.addListener(notifyListeners);
    this.width.addListener(notifyListeners);
  }

  MyBorderSide.from(MyBorderSide other)
      : color = VarField(other.color.variable),
        width = VarField(other.width.variable) {
    color.addListener(notifyListeners);
    width.addListener(notifyListeners);
  }

  @override
  void dispose() {
    color.removeListener(notifyListeners);
    width.removeListener(notifyListeners);
    color.dispose();
    width.dispose();
    super.dispose();
  }

  bool equals(MyBorderSide other) {
    return color.value == other.color.value && width.value == other.width.value;
  }
}

class VarField<T> extends ChangeNotifier {
  Variable<T> _variable;

  VarField(Variable<T> variable) : _variable = variable {
    if (_variable is ChangeNotifier) {
      (_variable as ChangeNotifier).addListener(notifyListeners);
    }
  }

  VarField.constant(T value) : _variable = ConstantVariable(value);

  Variable<T> get variable => _variable;
  T get value => variable.value;

  set variable(Variable<T> variable) {
    _variable = variable;

    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  void copy(VarField<T> other) {
    _variable = other.variable;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    if (_variable is ListenableVariable) {
      (_variable as ListenableVariable).dispose();
    }
  }
}

class MyShadow {
  final Variable<Color> color;
  final Variable<double> blurRadius;
  final Variable<Offset> offset;

  MyShadow({
    required this.color,
    required this.blurRadius,
    required this.offset,
  });
}
