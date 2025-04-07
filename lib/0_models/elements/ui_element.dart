import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/1_helpers/build/annotations.dart';
import 'package:jouhakka_forge/1_helpers/element_helper.dart';
import 'package:jouhakka_forge/2_services/actions.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

@DesignModel(
    description:
        "Abstract base class that BranchElement and LeafElement inherit from.")
abstract class UIElement extends ChangeNotifier {
  /// Every [UIElement] is part of an element tree, and every element tree has an [ElementRoot].
  ///
  /// This is the [ElementRoot] of the tree this [UIElement] is part of.
  final ElementRoot root;

  /// Every [UIElement] has a unique ID.
  final String id;

  /// If this [UIElement] is a child of another [UIElement], put the parent here.
  final ElementContainer? parent;

  @DesignFieldHolder(fields: ['width', 'height'])
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
        return TextElement(
            root: root, parent: parent, ConstantVariable("My Text"));
      case UIElementType.image:
        return ImageElement(root: root, parent: parent);
      case UIElementType.icon:
        return IconElement(root: root, parent: parent, icon: LucideIcons.star);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "width": size.width.toJson(),
      "height": size.height.toJson(),
    };
  }

  UIElement.fromJson(Map<String, dynamic> json, this.root, this.parent)
      : id = json["id"] ?? IDService.newElementID(root.id) {
    size.widthFromJson(json["width"], root);
    size.heightFromJson(json["height"], root);
  }

  static UIElement? tryFromJson(
    Map<String, dynamic>? json,
    ElementRoot root,
    ElementContainer? parent, {
    bool rethrowError = false,
  }) {
    if (json == null) return null;
    try {
      if (json["type"] == "branch") {
        return BranchElement.fromJson(json, root, parent);
      } else if (json["type"] == "leaf") {
        return LeafElement.tryFromJson(json, root, parent);
      }
      return null;
    } catch (e) {
      if (rethrowError) rethrow;
      return null;
    }
  }

  /// Returns the label of the [UIElement] that is shown in the [InspectorView].
  String get label => "Element";

  UpdateAction? setValue(String property, String value) {
    switch (property) {
      case "width":
        return UpdateAction<AxisSize>(
            oldValue: size.width,
            newValue: (size.widthFromJson(jsonDecode(value), root)),
            set: (value) => size.width = value);
      case "height":
        return UpdateAction<AxisSize>(
            oldValue: size.height,
            newValue: (size.heightFromJson(jsonDecode(value), root)),
            set: (value) => size.height = value);
    }
    return null;
  }

  MyAction? handleAction(String action, Map<String, String> args) {
    if (parent != null) {
      return size.handleAction(action, args, root);
    }

    switch (action) {
      case "setSize":
        return size.handleAction(
            args["dimension"] == "width" ? "width" : "height",
            {
              "type": args["sizeType"] ?? "controlled",
              "value": args["value"] ?? "0.0",
              "min": args["min"] ?? "0.0",
              "max": args["max"] ?? "inf",
              "flex": args["flex"] ?? "1.0",
            },
            root);
    }
    return null;
  }
}

@DesignModel(description: "UIElement that can have decoration and children.")
class BranchElement extends UIElement {
  /// The decoration settings of this [UIElement].
  @DesignField(
    description: "Decoration settings for the element.",
    defaultValue: "null",
  )
  late final OptionalProperty<ElementDecoration> decoration;

  @DesignField(
    description: "Contains children and information how they are displayed.",
    defaultValue: "null",
  )
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
  Map<String, dynamic> toJson() {
    return {
      "type": "branch",
      ...super.toJson(),
      "decoration": decoration.value?.toJson(),
      "content": content.value?.toJson(),
    };
  }

  BranchElement.fromJson(
      Map<String, dynamic> json, ElementRoot root, ElementContainer? parent)
      : super.fromJson(json, root, parent) {
    Map<String, dynamic>? decorationJson =
        (json["decoration"] as Map?)?.cast<String, dynamic>();
    decoration = OptionalProperty<ElementDecoration>(
        ElementDecoration.tryFromJson(decorationJson, root),
        listener: notifyListeners);
    Map<String, dynamic>? contentJson =
        (json["content"] as Map?)?.cast<String, dynamic>();
    content = OptionalProperty<ElementContainer>(
        ElementContainer.tryFromJson(contentJson, this),
        listener: notifyListeners);
  }

  @override
  String get label => content.value?.label ?? super.label;

  @override
  UpdateAction? setValue(String property, String value) {
    var setFunc = super.setValue(property, value);
    if (setFunc != null) return setFunc;

    if (property.startsWith("decoration.")) {
      if (decoration.value == null) {
        decoration.value = ElementDecoration();
      }
      return decoration.value!.setValue(property.substring(11), value, root);
    }
    if (property.startsWith("content.")) {
      if (content.value == null) {
        return null;
      }
      content.value!.setValue(property.substring(8), value);
    }
    return null;
  }

  @override
  MyAction? handleAction(String action, Map<String, String> args) {
    switch (action) {
      case "addChild":
        UIElementType? type;
        if (args["element"] != null) {
          if (args["element"] == "null") {
            type = null;
          } else if (args["element"] == "branch") {
            type = UIElementType.empty;
          } else {
            type = UIElementType.values.byName(args["element"]!);
          }
        }
        AddDirection? direction;
        if (args["direction"] != null && args["direction"] != "null") {
          direction = AddDirection.fromString(args["direction"]!);
        }
        addChildFromType(type, direction);
        return null;
      case "setDecoration":
        if (decoration.value == null) {
          decoration.value = ElementDecoration();
        }
        return decoration.value!.handleAction(action, args, root);
      case "setPadding":
      case "setSingleChildAlignment":
      case "setMultiChildProps":
        if (content.value != null) {
          return content.value!.handleAction(action, args);
        }
        return null;
    }
    return super.handleAction(action, args);
  }
}

@DesignModel(
    description:
        "Property of a BranchElement containing information about visual decoration.")
class ElementDecoration extends ChangeNotifier {
  /// Background color of the [UIElement] as a hex value.
  @DesignField(
    description: "Background color of the element.",
    defaultValue: "ConstantVariable(Colors.transparent)",
  )
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
    border.value = other.border.value?.clone(notifyListeners);
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

  Map<String, dynamic> toJson() {
    return {
      "backgroundColor": backgroundColor.variable.toString(),
      "radius": radius.toJson(),
      "border": border.value?.toJson() ?? {},
      //"margin": margin.value.toJson(),
    };
  }

  static ElementDecoration? tryFromJson(
      Map<String, dynamic>? json, ElementRoot root) {
    if (json == null) return null;
    try {
      return ElementDecoration.fromJson(json, root);
    } catch (e) {
      debugPrint("Failed to parse ElementDecoration: $e");
      return null;
    }
  }

  ElementDecoration.fromJson(Map<String, dynamic> json, ElementRoot root)
      : backgroundColor = VarField.fromInput(json["backgroundColor"], root) {
    {
      if (json["radius"] == null) {
        _radius = MyRadius.constantAll(0);
      } else {
        double? radius = double.tryParse(json["radius"].toString());
        if (radius == null) {
          _radius = MyRadius.fromJson(json["radius"], root, notifyListeners);
        } else {
          _radius = MyRadius.constantAll(radius);
        }
      }

      if (json["border"] == null) {
        border = OptionalProperty<MyBorder>(null, listener: notifyListeners);
      } else {
        Map<String, dynamic> borderJson = json["border"];
        if (borderJson.isEmpty) {
          border = OptionalProperty<MyBorder>(null, listener: notifyListeners);
        } else {
          border = OptionalProperty<MyBorder>(
              MyBorder.fromJson(json["border"], root, notifyListeners),
              listener: notifyListeners);
        }
      }
      //margin = OptionalProperty<EdgeInsets>(
      //    EdgeInsets.fromJson(json["margin"]), listener: notifyListeners);
    }
  }

  UpdateAction? setValue(
    String property,
    String value,
    ElementRoot root,
  ) {
    switch (property) {
      case "backgroundColor":
        return backgroundColor.setValue(value, root);
      case "radius":
        var old = radius;
        radius = MyRadius.fromJson(jsonDecode(value), root, notifyListeners);
        return UpdateAction<MyRadius>(
          oldValue: old,
          newValue: radius,
          set: (value) => radius = value,
        );

      case "border":
        var old = border.value;
        border.value = MyBorder.fromJson(
          jsonDecode(value),
          root,
          notifyListeners,
        );
        return UpdateAction<MyBorder?>(
          oldValue: old,
          newValue: border.value,
          set: (value) => border.value = value,
        );
    }
    return null;
  }

  UpdateAction? handleAction(
    String action,
    Map<String, String> args,
    ElementRoot root,
  ) {
    switch (action) {
      case "setDecoration":
        if (args["backgroundColor"] != null) {
          Variable<Color> old = backgroundColor.variable;
          backgroundColor.variable = VariableParser.parse<Color>(
              args["backgroundColor"]!, root,
              notifyListeners: notifyListeners);
          return UpdateAction<Variable<Color>>(
            oldValue: old,
            newValue: backgroundColor.variable,
            set: (value) => backgroundColor.variable = value,
          );
        }
        if (args["border"] != null) {
          final borderArgs =
              jsonDecode(args["border"]!) as Map<String, dynamic>;
          if (borderArgs["side"] != "null") {
            MyBorder? old = border.value;
            border.value = MyBorder.fromAction({
              "side": borderArgs["side"] as String,
              "width": borderArgs["width"] ?? "0.0",
              "color": borderArgs["color"] ?? "#000000FF",
            }, root, border.value, notifyListeners);
            return UpdateAction<MyBorder?>(
              oldValue: old,
              newValue: border.value,
              set: (value) => border.value = value,
            );
          }
        }
        if (args["radius"] != null) {
          final radiusArgs =
              jsonDecode(args["radius"]!) as Map<String, dynamic>;
          if (radiusArgs["corner"] != "null") {
            MyRadius old = radius;
            radius = MyRadius.fromAction({
              "side": radiusArgs["corner"] as String,
              "radius": radiusArgs["value"] ?? "0.0",
            }, root, radius);
            return UpdateAction<MyRadius>(
              oldValue: old,
              newValue: radius,
              set: (value) => radius = value,
            );
          }
        }
        return null;
    }
    return null;
  }
}
