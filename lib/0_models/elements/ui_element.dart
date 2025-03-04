import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
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
  final ElementContainer? parent;

  /// The width settings of this [UIElement].
  final AxisSize width = AxisSize();

  /// The height settings of this [UIElement].
  final AxisSize height = AxisSize();

  ElementContainer? tryGetContainer() {
    if (this is BranchElement) {
      return (this as BranchElement).content.value;
    }
    return null;
  }

  /// Base class for all UI elements
  UIElement({
    required this.root,
    required this.parent,
  }) : id = IDService.newElementID(root.id) {
    width.addListener(notifyListeners);
    height.addListener(notifyListeners);
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
  }

  UIElement clone({ElementRoot? root, ElementContainer? parent}) =>
      UIElement(root: root ?? this.root, parent: parent ?? this.parent)
        ..copy(this);

  /// Get different types of [UIElement] from a [UIElementType].
  static UIElement fromType(
      UIElementType type, ElementRoot root, ElementContainer? parent) {
    switch (type) {
      case UIElementType.empty:
        return UIElement(root: root, parent: parent);
      case UIElementType.box:
        return BranchElement.defaultBox(root, parent: parent);
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

class BranchElement extends UIElement {
  /// The decoration settings of this [UIElement].
  late final OptionalProperty<ElementDecoration> decoration;

  late final OptionalProperty<ElementContainer> content;

  BranchElement({
    required super.root,
    super.parent,
    ElementDecoration? decoration,
    (ElementContainerType, List<UIElement>)? content,
  }) {
    this.decoration = OptionalProperty<ElementDecoration>(decoration,
        listener: notifyListeners);

    this.content = OptionalProperty<ElementContainer>(
        content == null
            ? null
            : ElementContainer(
                element: this, type: content.$1, children: content.$2),
        listener: notifyListeners);
  }

  /// Expanding white box with black border and 8px padding.
  factory BranchElement.defaultBox(ElementRoot root,
      {ElementContainer? parent}) {
    BranchElement element = BranchElement(root: root, parent: parent);
    element.decoration.value = ElementDecoration()
      ..backgroundColor.value = Colors.white
      ..borderColor.value = Colors.black
      ..borderWidth.value = 1;
    return element;
  }

  void addContent(ElementContainerType type, List<UIElement> children) {
    content.value = ElementContainer(
      element: this,
      children: children,
      type: type,
    );
  }

  @override
  String get label => content.value?.label ?? super.label;
}

class ElementDecoration extends ChangeNotifier {
  /// Background color of the [UIElement] as a hex value.
  EV<Color> backgroundColor = EV(Colors.transparent);

  /// Corner radius of the [UIElement].
  EV<double> radius = EV(0);

  /// Border width of the [UIElement].
  EV<double> borderWidth = EV(0);

  /// Border color of the [UIElement] as a hex value.
  EV<Color> borderColor = EV(Colors.transparent);

  /// Margin of the [UIElement]. (Space outside the decoration)
  late final OptionalProperty<EdgeInsets> margin;

  /// Decoration settings for [UIElement]
  ElementDecoration({
    Color? backgroundColor,
    double? radius,
    double? borderWidth,
    Color? borderColor,
    EdgeInsets? margin,
  }) {
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
    this.backgroundColor.addListener(notifyListeners);
    this.radius.addListener(notifyListeners);
    this.borderWidth.addListener(notifyListeners);
    this.borderColor.addListener(notifyListeners);
    this.margin =
        OptionalProperty<EdgeInsets>(margin, listener: notifyListeners);
  }

  @override
  void dispose() {
    super.dispose();
    backgroundColor.dispose();
    radius.dispose();
    borderWidth.dispose();
    borderColor.dispose();
  }

  void copy(ElementDecoration other) {
    backgroundColor.copy(other.backgroundColor);
    radius.copy(other.radius);
    borderWidth.copy(other.borderWidth);
    borderColor.copy(other.borderColor);
    margin.value = other.margin.value;
  }

  ElementDecoration clone() => ElementDecoration()..copy(this);
}
