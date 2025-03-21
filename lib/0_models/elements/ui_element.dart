import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract class UIElement extends ChangeNotifier {
  /// Every [UIElement] is part of an element tree, and every element tree has an [ElementRoot].
  ///
  /// This is the [ElementRoot] of the tree this [UIElement] is part of.
  final ElementRoot root;

  /// Every [UIElement] has a unique ID.
  final String id;

  /// If this [UIElement] is a child of another [UIElement], put the parent here.
  final ElementContainer? parent;

  final SizeHolder size = SizeHolder.expand();

  /// The width settings of this [UIElement].
  //final AxisSizeOld width = AxisSizeOld();

  /// The height settings of this [UIElement].
  //final AxisSizeOld height = AxisSizeOld();

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
    size.addListener(notifyListeners);
    //width.addListener(notifyListeners);
    //height.addListener(notifyListeners);
  }

  @override
  void dispose() {
    super.dispose();
    size.dispose();
    //width.dispose();
    //height.dispose();
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

  void copy(UIElement other) {
    size.copy(other.size);
    //width.copy(other.width);
    //height.copy(other.height);
  }

  UIElement clone({ElementRoot? root, ElementContainer? parent});

  /// Get different types of [UIElement] from a [UIElementType].
  static UIElement fromType(
      UIElementType type, ElementRoot root, ElementContainer? parent) {
    switch (type) {
      case UIElementType.empty:
        return BranchElement(root: root, parent: parent);
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
    ElementContainer? content,
  }) {
    this.decoration = OptionalProperty<ElementDecoration>(decoration,
        listener: notifyListeners);

    this.content = OptionalProperty<ElementContainer>(
        content?.clone(element: this),
        listener: notifyListeners);
  }

  /// Expanding white box with black border and 8px padding.
  factory BranchElement.defaultBox(ElementRoot root,
      {ElementContainer? parent}) {
    BranchElement element = BranchElement(
        root: root, parent: parent, decoration: ElementDecoration.defaultBox);
    return element;
  }

  @override
  BranchElement clone({ElementRoot? root, ElementContainer? parent}) =>
      BranchElement(
        root: root ?? this.root,
        parent: parent ?? this.parent,
        decoration: decoration.value?.clone(),
        //Cloned in the constructor
        content: content.value,
      );

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
  final VarField<Color> backgroundColor;

  /// Corner radius of the [UIElement].
  late MyRadius _radius;
  MyRadius get radius => _radius;
  set radius(MyRadius value) {
    _radius = value.clone(notifyListeners);
    notifyListeners();
  }

  /// Border of the [UIElement].
  late final OptionalProperty<MyBorder> border;

  DecoratedBox get decoratedBox {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor.value,
        borderRadius: radius.borderRadius,
        border: border.value?.boxBorder,
      ),
    );
  }

  /// Margin of the [UIElement]. (Space outside the decoration)
  // late final OptionalProperty<EdgeInsets> margin;

  /// Decoration settings for [UIElement]
  ElementDecoration({
    Color? backgroundColor,
    MyRadius? radius,
    MyBorder? border,
    EdgeInsets? margin,
  })  : backgroundColor =
            VarField<Color>.constant(backgroundColor ?? Colors.transparent),
        _radius = radius ?? MyRadius.constantAll(0) {
    this.backgroundColor.addListener(notifyListeners);
    this.radius = radius ?? MyRadius.constantAll(0);
    this.border = OptionalProperty<MyBorder>(border, listener: notifyListeners);
    //this.margin = OptionalProperty<EdgeInsets>(margin, listener: notifyListeners);
  }

  static ElementDecoration get defaultBox => ElementDecoration(
        backgroundColor: Colors.white,
        border: MyBorder.defaultBorder,
      );

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();

    backgroundColor.dispose();

    border.dispose();
    //margin.dispose();
  }

  void copy(ElementDecoration other) {
    backgroundColor.copy(other.backgroundColor);
    radius = other.radius.clone(notifyListeners);
    border.value = other.border.value?.clone();
    //margin.value = other.margin.value;
  }

  ElementDecoration clone() => ElementDecoration()..copy(this);

  bool equals(ElementDecoration other) {
    return backgroundColor.value == other.backgroundColor.value &&
        radius == other.radius &&
        (border.hasValueNotifier.value == other.border.hasValueNotifier.value &&
                border.value == null
            ? true
            : border.value!.equals(other.border.value!));
    //&& margin.value == other.margin.value;
  }
}
