import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class UIElement extends ChangeNotifier {
  /// Every [UIElement] is part of an element tree, and every element tree has an [ElementRoot].
  ///
  /// This is the [ElementRoot] of the tree this [UIElement] is part of.
  final ElementRoot root;

  /// Every [UIElement] has a unique ID.
  final String id;

  /// If this [UIElement] is a child of another [UIElement], put the parent here.
  final ContainerElement? parent;

  /// The width settings of this [UIElement].
  final AxisSize width = AxisSize();

  /// The height settings of this [UIElement].
  final AxisSize height = AxisSize();

  /// The padding settings of this [UIElement]. (Space between the element borders and the content)
  late final OptionalProperty<EdgeInsets> padding;

  /// The decoration settings of this [UIElement].
  late final OptionalProperty<ElementDecoration> decoration;

  /// Base class for all UI elements
  UIElement({
    required this.root,
    required this.parent,
  }) : id = IDService.newElementID(root.id) {
    width.addListener(notifyListeners);
    height.addListener(notifyListeners);
    padding = OptionalProperty(null, listener: notifyListeners);
    decoration = OptionalProperty(null, listener: notifyListeners);
  }

  @override
  void dispose() {
    super.dispose();
    width.dispose();
    height.dispose();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  /// Expanding white box with black border and 8px padding.
  factory UIElement.defaultBox(ElementRoot root, {ContainerElement? parent}) {
    UIElement element = UIElement(root: root, parent: parent);
    element.padding.value = const EdgeInsets.all(8);
    element.decoration.value = ElementDecoration()
      ..backgroundColor.value = Colors.white
      ..borderColor.value = Colors.black
      ..borderWidth.value = 1;
    return element;
  }

  Widget? getContent() {
    return null;
  }

  Widget? getContentAsWireframe() {
    return null;
  }

  /// Combines the `width` and `height` settings to a [Resolution] object.
  ///
  /// Returns `null` if either `width` or `height` value cannot be resolved.
  Resolution? getResolution() {
    if (width.value == null || height.value == null) return null;
    return Resolution(width: width.value!, height: height.value!);
  }

  /// If `axis` is not specified, returns `true` if either `width` or `height` expands.
  ///
  /// If `axis` is specified, returns `true` if the specified `axis` expands.
  bool expands({Axis? axis}) {
    if (axis == null) {
      return width.type == SizeType.expand || height.type == SizeType.expand;
    } else if (axis == Axis.horizontal) {
      return width.type == SizeType.expand;
    } else {
      return height.type == SizeType.expand;
    }
  }

  void copy(UIElement other) {
    width.copy(other.width);
    height.copy(other.height);
    padding.value = other.padding.value;
    decoration.value = other.decoration.value;
  }

  UIElement clone({ElementRoot? root, ContainerElement? parent}) {
    UIElement copy =
        UIElement(root: root ?? this.root, parent: parent ?? this.parent);
    copy.width.copy(width);
    copy.height.copy(height);
    copy.padding.value = padding.value;
    copy.decoration.value = decoration.value;
    return copy;
  }

  /// Get different types of [UIElement] from a [UIElementType].
  static UIElement fromType(
      UIElementType type, ElementRoot root, ContainerElement? parent) {
    switch (type) {
      case UIElementType.empty:
        return UIElement(root: root, parent: parent);
      case UIElementType.box:
        return UIElement.defaultBox(root, parent: parent);
      case UIElementType.text:
        return TextElement(root: root, parent: parent);
      case UIElementType.image:
        return ImageElement(root: root, parent: parent);
      case UIElementType.icon:
        return IconElement(root: root, parent: parent, icon: LucideIcons.star);
    }
  }

  /// Returns the label of the [UIElement] that is shown in the [InspectorView].
  String get label => "Element";
}

class OptionalProperty<T> {
  T? _value;
  final Function() listener;
  T? get value => _value;
  set value(T? value) {
    if (value == _value) return;
    dispose();
    _value = value;
    forwardListener();
    listener();
  }

  OptionalProperty(
    T? value, {
    required this.listener,
  }) : _value = value {
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

  bool get hasValue => _value != null;

  bool get isNull => _value == null;

  bool ifValue(void Function(T) callback) {
    if (_value != null) {
      try {
        callback(_value as T);
        return true;
      } catch (e, s) {
        debugPrint("Error in OptionalProperty<$T>.ifValue: $e | $s");
      }
    }

    return false;
  }
}

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
  }

  void setConstantValue(T value) {
    _value = value;
    source = ValueSource.constant;
    variableKey = null;
  }

  T get value => _value;

  set value(T value) {
    _value = value;
    source = ValueSource.constant;
  }
}

class CompositeEV<T> extends EV<T> {
  //TODO: Implement composite value
  CompositeEV(EV<T> value) : super(value.value, source: ValueSource.composite) {
    source = ValueSource.composite;
  }
}

class ElementDecoration extends ChangeNotifier {
  /// Background color of the [UIElement] as a hex value.
  EV<Color?> backgroundColor = EV(null);

  /// Corner radius of the [UIElement].
  EV<double> radius = EV(0);

  /// Border width of the [UIElement].
  EV<double> borderWidth = EV(0);

  /// Border color of the [UIElement] as a hex value.
  EV<Color?> borderColor = EV(null);

  /// Margin of the [UIElement]. (Space outside the decoration)
  EdgeInsetsGeometry? margin;

  /// Decoration settings for [UIElement]
  ElementDecoration(
      {Color? backgroundColor,
      double? radius,
      double? borderWidth,
      Color? borderColor}) {
    if (backgroundColor != null) {
      this.backgroundColor.value = backgroundColor;
    }
    if (radius != null) {
      this.radius.value = radius;
    }
    if (borderWidth != null) {
      this.borderWidth.value = borderWidth;
    }
    if (borderColor != null) {
      this.borderColor.value = borderColor;
    }
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
