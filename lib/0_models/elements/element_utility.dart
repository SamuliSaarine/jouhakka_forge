import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/1_helpers/build/annotations.dart';
import 'package:jouhakka_forge/2_services/actions.dart';

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
      debugPrint("Error in setRootVariable: $e");
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

  Map<String, dynamic> toJson();

  static AxisSize fromJson(Map<String, dynamic> json, ElementRoot root,
      void Function() notifyListeners) {
    switch (json['type']) {
      case "controlled":
        return ControlledSize.fromJson(json, root, notifyListeners);
      case "shrink":
        return ShrinkingSize.fromJson(json, root, notifyListeners);
      case "expand":
        return ExpandingSize.fromJson(json, root, notifyListeners);
      default:
        throw Exception("Invalid AxisSize type: ${json['type']}");
    }
  }
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
  Map<String, dynamic> toJson() {
    return {
      "type": "controlled",
      "value": value.toString(),
    };
  }

  @override
  double get renderValue => value.value;

  ControlledSize.fromJson(Map<String, dynamic> json, ElementRoot root,
      void Function() notifyListeners)
      : value = VariableParser.parse(json['value'], root,
            notifyListeners: notifyListeners);
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

  @override
  Map<String, dynamic> toJson() {
    return {
      "min": min.toString(),
      "max": max.toString(),
    };
  }
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

  @override
  Map<String, dynamic> toJson() => {
        "type": "shrink",
        ...super.toJson(),
      };

  ShrinkingSize.fromJson(Map<String, dynamic> json, ElementRoot root,
      void Function() notifyListeners)
      : super(
          min: VariableParser.parse(json['min'], root,
              notifyListeners: notifyListeners),
          max: VariableParser.parse(json['max'], root,
              notifyListeners: notifyListeners),
        );
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

  @override
  Map<String, dynamic> toJson() => {
        'type': 'expand',
        ...super.toJson(),
        'flex': flex.toString(),
      };

  ExpandingSize.fromJson(Map<String, dynamic> json, ElementRoot root,
      void Function() notifyListeners)
      : flex = VariableParser.parse(json['flex'], root,
            notifyListeners: notifyListeners),
        super(
          min: VariableParser.parse(json['min'], root,
              notifyListeners: notifyListeners),
          max: VariableParser.parse(json['max'], root,
              notifyListeners: notifyListeners),
        );
}

class SizeHolder extends ChangeNotifier {
  @DesignField(
      description: "Width of the element", defaultValue: "ExpandingSize")
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

  AxisSize widthFromJson(
    Map<String, dynamic> json,
    ElementRoot root,
  ) {
    _width = AxisSize.fromJson(json, root, notifyListeners);
    notifyListeners();
    return _width;
  }

  AxisSize heightFromJson(
    Map<String, dynamic> json,
    ElementRoot root,
  ) {
    _height = AxisSize.fromJson(json, root, notifyListeners);
    notifyListeners();
    return _height;
  }

  UpdateAction? handleAction(
    String action,
    Map<String, String> args,
    ElementRoot root,
  ) {
    Variable<double>? min;
    if (args['min'] != null) {
      min = VariableParser.parse(args['min']!, root,
          notifyListeners: notifyListeners);
    }
    Variable<double>? max;
    if (args['max'] != null) {
      max = VariableParser.parse(args['max']!, root,
          notifyListeners: notifyListeners);
    }
    Variable<int>? flex;
    if (args['flex'] != null) {
      flex = VariableParser.parse(args['flex']!, root,
          notifyListeners: notifyListeners);
    }
    Variable<double>? controlled;
    if (args['value'] != null) {
      controlled = VariableParser.parse(args['value']!, root,
          notifyListeners: notifyListeners);
    }
    AxisSize oldWidth = _width;
    AxisSize oldHeight = _height;

    switch (action) {
      case "expandWidth":
        width = ExpandingSize(min: min, max: max, flex: flex);
        break;
      case "expandHeight":
        height = ExpandingSize(min: min, max: max, flex: flex);
        break;
      case "hugWidth":
        width = ShrinkingSize(min: min, max: max);
        break;
      case "hugHeight":
        height = ShrinkingSize(min: min, max: max);
        break;
      case "controlledWidth":
        width = ControlledSize(controlled!);
        break;
      case "controlledHeight":
        height = ControlledSize(controlled!);
        break;
      default:
        return null;
    }
    if (width != oldWidth) {
      return UpdateAction(
        oldValue: oldWidth,
        newValue: width,
        set: (value) => width = value,
      );
    }
    if (height != oldHeight) {
      return UpdateAction(
        oldValue: oldHeight,
        newValue: height,
        set: (value) => height = value,
      );
    }
    return null;
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

  Map<String, dynamic> toJson() {
    return {
      "topLeft": topLeft.toString(),
      "topRight": topRight.toString(),
      "bottomRight": bottomRight.toString(),
      "bottomLeft": bottomLeft.toString(),
    };
  }

  MyRadius.fromJson(Map<String, dynamic> json, ElementRoot root,
      void Function() notifyListeners)
      : topLeft = VariableParser.parse(json['topLeft'], root,
            notifyListeners: notifyListeners),
        topRight = VariableParser.parse(json['topRight'], root,
            notifyListeners: notifyListeners),
        bottomRight = VariableParser.parse(json['bottomRight'], root,
            notifyListeners: notifyListeners),
        bottomLeft = VariableParser.parse(json['bottomLeft'], root,
            notifyListeners: notifyListeners);

  factory MyRadius.fromAction(
      Map<String, String> args, ElementRoot root, MyRadius? old) {
    String side = args['side'] ?? "all";
    Variable<double> newValue = VariableParser.parse(
        args['radius'] ?? "0.0", root,
        notifyListeners: () {});
    if (side == "all") {
      return MyRadius(
          topLeft: newValue,
          topRight: newValue,
          bottomRight: newValue,
          bottomLeft: newValue);
    } else {
      return MyRadius(
        topLeft:
            side == "topLeft" ? newValue : old?.topLeft ?? ConstantVariable(0),
        topRight: side == "topRight"
            ? newValue
            : old?.topRight ?? ConstantVariable(0),
        bottomRight: side == "bottomRight"
            ? newValue
            : old?.bottomRight ?? ConstantVariable(0),
        bottomLeft: side == "bottomLeft"
            ? newValue
            : old?.bottomLeft ?? ConstantVariable(0),
      );
    }
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

  Map<String, dynamic> toJson() {
    return {
      "top": top.toString(),
      "bottom": bottom.toString(),
      "left": left.toString(),
      "right": right.toString(),
    };
  }

  MyPadding.fromJson(Map<String, dynamic> json, ElementRoot root,
      void Function() notifyListeners)
      : top = VariableParser.parse(json['top'], root,
            notifyListeners: notifyListeners),
        bottom = VariableParser.parse(json['bottom'], root,
            notifyListeners: notifyListeners),
        left = VariableParser.parse(json['left'], root,
            notifyListeners: notifyListeners),
        right = VariableParser.parse(json['right'], root,
            notifyListeners: notifyListeners);

  factory MyPadding.fromAction(
      Map<String, String> args, ElementRoot root, MyPadding? old) {
    String side = args['side'] ?? "all";
    Variable<double> newValue = VariableParser.parse(
        args['padding'] ?? "0.0", root,
        notifyListeners: () {});
    if (side == "all") {
      return MyPadding(
          top: newValue, bottom: newValue, left: newValue, right: newValue);
    } else {
      return MyPadding(
        top: side == "top" ? newValue : old?.top ?? ConstantVariable(0),
        bottom:
            side == "bottom" ? newValue : old?.bottom ?? ConstantVariable(0),
        left: side == "left" ? newValue : old?.left ?? ConstantVariable(0),
        right: side == "right" ? newValue : old?.right ?? ConstantVariable(0),
      );
    }
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

  Map<String, dynamic> toJson() {
    return {
      "top": top.toJson(),
      "right": right.toJson(),
      "bottom": bottom.toJson(),
      "left": left.toJson(),
    };
  }

  MyBorder.fromJson(Map<String, dynamic> json, ElementRoot root)
      : top = MyBorderSide.fromJson(json['top'], root),
        right = MyBorderSide.fromJson(json['right'], root),
        bottom = MyBorderSide.fromJson(json['bottom'], root),
        left = MyBorderSide.fromJson(json['left'], root);

  factory MyBorder.fromAction(
      Map<String, String> args, ElementRoot root, MyBorder? old) {
    String side = args['side'] ?? "all";
    MyBorderSide newSide = MyBorderSide.fromJson(args, root);
    if (side == "all") {
      return MyBorder(
        top: newSide,
        right: newSide,
        bottom: newSide,
        left: newSide,
      );
    } else {
      return MyBorder(
        top: side == "top" ? newSide : old?.top ?? MyBorder.defaultBorder.top,
        right: side == "right"
            ? newSide
            : old?.right ?? MyBorder.defaultBorder.right,
        bottom: side == "bottom"
            ? newSide
            : old?.bottom ?? MyBorder.defaultBorder.bottom,
        left:
            side == "left" ? newSide : old?.left ?? MyBorder.defaultBorder.left,
      );
    }
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

  Map<String, dynamic> toJson() {
    return {
      "color": color.variable.toString(),
      "width": width.variable.toString(),
    };
  }

  MyBorderSide.fromJson(Map<String, dynamic> json, ElementRoot root)
      : color = VarField.fromInput(json['color'] ?? "#000000FF", root),
        width = VarField.fromInput(json['width'] ?? "1.0", root) {
    color.addListener(notifyListeners);
    width.addListener(notifyListeners);
  }
}

class VarField<T> extends ChangeNotifier {
  late Variable<T> _variable;

  VarField(Variable<T> variable) : _variable = variable {
    if (_variable is ChangeNotifier) {
      (_variable as ChangeNotifier).addListener(notifyListeners);
    }
  }

  VarField.constant(T value) : _variable = ConstantVariable(value);

  VarField.fromInput(String input, ElementRoot root) {
    _variable =
        VariableParser.parse(input, root, notifyListeners: notifyListeners);
  }

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

  UpdateAction<Variable<T>> setValue(String value, ElementRoot root) {
    var old = _variable;
    _variable =
        VariableParser.parse(value, root, notifyListeners: notifyListeners);
    return UpdateAction(
      oldValue: old,
      newValue: _variable,
      set: (value) => variable = value,
    );
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
