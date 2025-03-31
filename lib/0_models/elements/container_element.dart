import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/1_helpers/build/annotations.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/2_services/actions.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import '../../3_components/element/ui_element_component.dart';

part 'container_element.g.dart';

@notifier
class ElementContainer extends ChangeNotifier {
  final BranchElement element;

  /// List of [UIElement]s that are direct children of this container.
  final List<UIElement> children = [];
  final ChangeNotifier childNotifier = ChangeNotifier();

  /// Specifies how the [ElementContainer] acts and is displayed.
  ElementContainerType _type;
  ElementContainerType get type => _type;
  set type(ElementContainerType value) {
    _type = value;
    _type.addListener(notifyListeners);
    _type.notifyListeners();
  }

  @notify
  MyPadding _padding = MyPadding.zero;

  @notify
  ContentOverflow _overflow = ContentOverflow.clip;

  /// [UIElement] that can contain one or more [UIElement]s.
  ElementContainer({
    required this.element,
    List<UIElement> children = const [],
    required ElementContainerType type,
  }) : _type = type {
    _type.addListener(notifyListeners);
    for (UIElement child in children) {
      addChild(child);
    }
  }

  ElementContainer.singleChildFromType({
    required this.element,
    required UIElementType childType,
  }) : _type = SingleChildElementType() {
    _type.addListener(notifyListeners);
    addChild(UIElement.fromType(childType, element.root, this));
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  UIElement addChild(UIElement child) {
    if (type is SingleChildElementType && children.isNotEmpty) {
      throw Exception(
          "SingleChildElementType can only have one child. Change the container type first.");
    }

    if (child.parent != this) {
      child = child.clone();
    }

    /*if (type.scroll != null) {
      if (type.scroll == Axis.horizontal) {
        child.width.fixed(200);
      } else {
        child.height.fixed(200);
      }
    }*/
    children.add(child);
    childNotifier.notifyListeners();
    return child;
  }

  void removeChild(UIElement child) {
    if (Session.selectedElement.value == child) {
      Session.selectedElement.value = null;
    }
    children.remove(child);
    if (children.length == 1 && type is! SingleChildElementType) {
      type = SingleChildElementType();
    } else if (children.isEmpty) {
      element.content.value = null;
      return;
    }
    childNotifier.notifyListeners();
  }

  void insertChild(int index, UIElement child) {
    if (type is SingleChildElementType && children.isNotEmpty) {
      throw Exception(
          "SingleChildElementType can only have one child. Change the container type first.");
    }

    if (child.parent != this) {
      child = child.clone();
    }

    children.insert(index, child);
    childNotifier.notifyListeners();
  }

  void reorderChild(int oldIndex, int newIndex) {
    final UIElement child = children.removeAt(oldIndex);
    children.insert(newIndex, child);
    childNotifier.notifyListeners();
  }

  int indexOf(UIElement element) => children.indexOf(element);

  void replaceAt(int index, UIElement element) {
    assert(index >= 0 && index < children.length, "Index out of bounds");
    bool needsClone =
        element.parent != this || element.root != this.element.root;
    children[index] = needsClone
        ? element.clone(root: this.element.root, parent: this)
        : element;
    childNotifier.notifyListeners();
  }

  void changeContainerType(ElementContainerType newType) {
    //Axis? oldScroll = type.scroll;
    type = newType; //..scroll = oldScroll;
  }

  //TODO: Used only in play mode, test this when play mode is implemented
  /// Returns the content of the container.
  Widget? getContent() {
    if (children.isEmpty) return null;
    if (children.length == 1) {
      return ElementWidget(
        element: children.first,
        globalKey: GlobalKey(),
        canApplyInfinity: true,
      );
    }
    List<Widget> widgetChildren = children
        .map(
          (e) => ElementWidget(
              element: e, globalKey: GlobalKey(), canApplyInfinity: false),
        )
        .toList();
    if (type is FlexElementType) {
      AxisSize axisSize =
          element.size.getAxis((type as FlexElementType).direction);
      bool hugContent = axisSize is AutomaticSize;
      return (type as FlexElementType).getWidget(
        widgetChildren,
        mainAxisSize: hugContent ? MainAxisSize.min : MainAxisSize.max,
      );
    }
    return type.getWidget(widgetChildren);
  }

  void copy(ElementContainer other) {
    if (other.type.runtimeType == type.runtimeType) {
      type.copy(other.type);
    }
  }

  ElementContainer clone({BranchElement? element}) {
    ElementContainer newElement = ElementContainer(
      element: element ?? this.element,
      type: type.clone(),
    );
    newElement.copy(this);
    for (UIElement child in children) {
      newElement.addChild(
        child.clone(
          root: newElement.element.root,
          parent: newElement,
        ),
      );
    }
    return newElement;
  }

  Map<String, dynamic> toJson() {
    return {
      "padding": padding.toJson(),
      "overflow": overflow.toString(),
      "type": type.toJson(),
      "children": children.map((e) => e.toJson()).toList(),
    };
  }

  static ElementContainer? tryFromJson(
      Map<String, dynamic>? json, BranchElement element) {
    if (json == null) return null;
    try {
      return ElementContainer.fromJson(json, element, element.root);
    } catch (e, s) {
      debugPrint("Error in ElementContainer.fromJson: $e $s");
      return null;
    }
  }

  ElementContainer.fromJson(
      Map<String, dynamic> json, this.element, ElementRoot root)
      : _type = ElementContainerType.fromJson(json["type"], root) {
    if (json.containsKey("padding")) {
      _padding = MyPadding.fromJson(json["padding"], root, notifyListeners);
    }

    String? overflowString = json["overflow"];
    for (ContentOverflow value in ContentOverflow.values) {
      if (value.toString() == overflowString) {
        overflow = value;
        break;
      }
    }
    List<Map<String, dynamic>>? childrenJson =
        (json["children"] as List?)?.cast<Map<String, dynamic>>();
    if (childrenJson != null) {
      for (Map<String, dynamic> childJson in childrenJson) {
        UIElement? child = UIElement.tryFromJson(childJson, root, this);
        if (child != null) {
          children.add(child);
        }
      }
    }
    if (children.isEmpty) {
      element.content.value = null;
    }
  }

  UpdateAction? setValue(String property, String value) {
    switch (property) {
      case "padding":
        var old = padding;
        padding = MyPadding.fromJson(
            jsonDecode(value), element.root, notifyListeners);
        return UpdateAction<MyPadding>(
          oldValue: old,
          newValue: padding,
          set: (v) => padding = v,
        );
      case "overflow":
        var old = overflow;
        overflow = ContentOverflow.fromString(value);
        return UpdateAction<ContentOverflow>(
          oldValue: old,
          newValue: overflow,
          set: (v) => overflow = v,
        );
      case "type":
        var old = type;
        type = ElementContainerType.fromJson(jsonDecode(value), element.root);
        return UpdateAction<ElementContainerType>(
          oldValue: old,
          newValue: type,
          set: (v) => type = v,
        );
    }
    if (property.startsWith("type.")) {
      String subProperty = property.substring(5);
      return type.setValue(subProperty, value, element.root);
    } else {
      debugPrint("Unknown property: $property");
      return null;
    }
  }

  UpdateAction? handleAction(String action, Map<String, String> args) {
    try {
      if (action == "setPadding") {
        MyPadding old = padding;
        padding = MyPadding.fromAction(args, element.root, old);
        return UpdateAction<MyPadding>(
          oldValue: old,
          newValue: padding,
          set: (v) => padding = v,
        );
      } else if (action == "setOverflow") {
        ContentOverflow old = overflow;
        overflow = ContentOverflow.fromString(args["overflow"]!);
        return UpdateAction<ContentOverflow>(
          oldValue: old,
          newValue: overflow,
          set: (v) => overflow = v,
        );
      } else {}
    } catch (e) {
      debugPrint("Error in handleAction: $e");
      return null;
    }
  }

  String get label => type.label;
}

enum ContentOverflow {
  allow,
  clip,
  horizontalScroll,
  verticalScroll;

  static ContentOverflow fromString(String value) {
    switch (value) {
      case "allow":
        return ContentOverflow.allow;
      case "clip":
        return ContentOverflow.clip;
      case "horizontalScroll":
        return ContentOverflow.horizontalScroll;
      case "verticalScroll":
        return ContentOverflow.verticalScroll;
      default:
        throw Exception("Unknown ContentOverflow value: $value");
    }
  }
}

abstract class ElementContainerType extends ChangeNotifier {
  /// Returns a [Widget] that contains the children.
  Widget getWidget(List<Widget> children);
  String get label;

  ElementContainerType clone();

  void copy(ElementContainerType other) {}

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  Map<String, dynamic> toJson();

  static ElementContainerType fromJson(
      Map<String, dynamic> json, ElementRoot root) {
    String type = json["type"];
    switch (type) {
      case "single":
        return SingleChildElementType.fromJson(json);
      case "flex":
        return FlexElementType.fromJson(json, root);
      default:
        throw Exception("Unknown container type: $type");
    }
  }

  UpdateAction? setValue(String property, String value, ElementRoot root);

  UpdateAction? handleAction(String action, Map<String, String> args);
}

@notifier
class SingleChildElementType extends ElementContainerType {
  @notify
  Alignment _alignment = Alignment.center;

  /// [ElementContainerType] that can only have one child.
  SingleChildElementType();

  @override
  Widget getWidget(List<Widget> children, {bool align = true}) {
    if (children.length != 1) {
      throw Exception(
          "SingleChildElementType can only have one child. Try to change the container type.");
    }

    Widget current = children.first;

    // Wrap in SingleChildScrollView if scroll is enabled and ctrl is pressed
    /*if (scroll != null) {
      try {
        double initialOffset = PageDesignView.scrollStates[hashCode] ?? 0.0;
        ScrollController controller =
            ScrollController(initialScrollOffset: initialOffset);
        controller.addListener(() {
          PageDesignView.scrollStates[hashCode] = controller.offset;
        });
        current = GestureDetector(
          onVerticalDragUpdate: (details) {
            debugPrint("Drag update");
          },
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: scroll!,
            physics: const AlwaysScrollableScrollPhysics(),
            restorationId: hashCode.toString(),
            child: children.first,
          ),
        );
      } catch (e, s) {
        debugPrint("Error in SingleChildScrollView: $e $s");
      }
    }*/

    return Align(alignment: alignment, child: current);
  }

  @override
  ElementContainerType clone() => SingleChildElementType()..copy(this);

  @override
  void copy(ElementContainerType other) {
    super.copy(other);
    if (other is SingleChildElementType) {
      alignment = other.alignment;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "single",
      "alignment": alignment.toJson(),
    };
  }

  SingleChildElementType.fromJson(Map<String, dynamic> json) {
    alignment = AlignmentExtension.fromString(json["alignment"],
        defaultValue: Alignment.center);
  }

  @override
  UpdateAction? setValue(String property, String value, ElementRoot root) {
    switch (property) {
      case "alignment":
        var old = alignment;
        alignment = AlignmentExtension.fromString(value,
            defaultValue: Alignment.center);
        return UpdateAction<Alignment>(
          oldValue: old,
          newValue: alignment,
          set: (v) => alignment = v,
        );
    }
    return null;
  }

  @override
  UpdateAction? handleAction(String action, Map<String, String> args) {
    try {
      if (action == "setAlignment") {
        Alignment old = alignment;
        alignment = AlignmentExtension.fromString(args["alignment"]!,
            defaultValue: Alignment.center);
        return UpdateAction<Alignment>(
          oldValue: old,
          newValue: alignment,
          set: (v) => alignment = v,
        );
      }
    } catch (e) {
      debugPrint("Error in handleAction: $e");
    }
    return null;
  }

  @override
  String get label => "Container";
}

//TODO: Test and fix stretch more
@notifier
class FlexElementType extends ElementContainerType {
  @notify
  Axis _direction = Axis.vertical;

  @notify
  MainAxisAlignment _mainAxisAlignment = MainAxisAlignment.spaceEvenly;

  @notify
  CrossAxisAlignment _crossAxisAlignment = CrossAxisAlignment.start;

  @notify
  Variable<double> _spacing = ConstantVariable<double>(0);

  /// [ElementContainerType] that arranges children in a row or column.
  FlexElementType(
    Axis direction,
  ) : _direction = direction;

  @override
  Widget getWidget(List<Widget> children,
      {MainAxisSize mainAxisSize = MainAxisSize.max}) {
    List<Widget> spacedChildren = [];
    if (spacing.value > 0 && children.length > 1) {
      // Add sized box between each child
      for (int i = 0; i < children.length; i++) {
        if (i != 0) {
          spacedChildren.add(SizedBox(
            width: direction == Axis.horizontal ? spacing.value : null,
            height: direction == Axis.vertical ? spacing.value : null,
          ));
        }
        spacedChildren.add(children[i]);
      }
    }

    Widget current = Flex(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      direction: direction,
      children: spacedChildren.isEmpty ? children : spacedChildren,
    );

    /*if (scroll != null) {
      try {
        double initialOffset = PageDesignView.scrollStates[hashCode] ?? 0.0;
        ScrollController controller =
            ScrollController(initialScrollOffset: initialOffset);
        controller.addListener(() {
          PageDesignView.scrollStates[hashCode] = controller.offset;
        });
        current = SingleChildScrollView(
          controller: controller,
          scrollDirection: scroll!,
          physics: const AlwaysScrollableScrollPhysics(),
          restorationId: hashCode.toString(),
          child: current,
        );
      } catch (e, s) {
        debugPrint("Error in SingleChildScrollView: $e $s");
      }
    }*/
    return current;
  }

  @override
  ElementContainerType clone() => FlexElementType(direction)..copy(this);

  @override
  void copy(ElementContainerType other) {
    super.copy(other);
    if (other is FlexElementType) {
      direction = other.direction;
      mainAxisAlignment = other.mainAxisAlignment;
      crossAxisAlignment = other.crossAxisAlignment;
      spacing = other.spacing;
    }
  }

  @override
  String get label => "Flex";

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "flex",
      "direction": direction.toString(),
      "mainAxisAlignment": mainAxisAlignment.toString(),
      "crossAxisAlignment": crossAxisAlignment.toString(),
      "spacing": spacing.toString(),
    };
  }

  FlexElementType.fromJson(Map<String, dynamic> json, ElementRoot root) {
    direction =
        json["direction"] == "vertical" ? Axis.vertical : Axis.horizontal;

    String? mainAxisString = json["mainAxisAlignment"];
    for (MainAxisAlignment value in MainAxisAlignment.values) {
      if (value.toString() == mainAxisString) {
        mainAxisAlignment = value;
        break;
      }
    }

    String? crossAxisString = json["crossAxisAlignment"];
    for (CrossAxisAlignment value in CrossAxisAlignment.values) {
      if (value.toString() == crossAxisString) {
        crossAxisAlignment = value;
        break;
      }
    }

    if (json.containsKey("spacing")) {
      spacing = VariableParser.parse<double>(json['spacing'], root,
          notifyListeners: notifyListeners);
    }
  }

  @override
  UpdateAction? setValue(String property, String value, ElementRoot root) {
    switch (property) {
      case "direction":
        var old = direction;
        direction = value == "vertical" ? Axis.vertical : Axis.horizontal;
        return UpdateAction<Axis>(
          oldValue: old,
          newValue: direction,
          set: (v) => direction = v,
        );
      case "mainAxisAlignment":
        var old = mainAxisAlignment;
        mainAxisAlignment = MainAxisAlignment.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => MainAxisAlignment.start);
        return UpdateAction<MainAxisAlignment>(
          oldValue: old,
          newValue: mainAxisAlignment,
          set: (v) => mainAxisAlignment = v,
        );
      case "crossAxisAlignment":
        var old = crossAxisAlignment;
        crossAxisAlignment = CrossAxisAlignment.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => CrossAxisAlignment.start);
        return UpdateAction<CrossAxisAlignment>(
          oldValue: old,
          newValue: crossAxisAlignment,
          set: (v) => crossAxisAlignment = v,
        );
      case "spacing":
        var old = spacing;
        spacing = VariableParser.parse<double>(value, root,
            notifyListeners: notifyListeners);
        return UpdateAction<Variable<double>>(
          oldValue: old,
          newValue: spacing,
          set: (v) => spacing = v,
        );
    }
    return null;
  }

  @override
  UpdateAction? handleAction(String action, Map<String, String> args,
      {ElementRoot? root}) {
    try {
      if (action == "setDirection") {
        Axis old = direction;
        direction =
            args["direction"] == "vertical" ? Axis.vertical : Axis.horizontal;
        return UpdateAction<Axis>(
          oldValue: old,
          newValue: direction,
          set: (v) => direction = v,
        );
      } else if (action == "setMainAxisAlignment") {
        MainAxisAlignment old = mainAxisAlignment;
        mainAxisAlignment = MainAxisAlignment.values.firstWhere(
            (e) => e.toString() == args["mainAxisAlignment"],
            orElse: () => MainAxisAlignment.start);
        return UpdateAction<MainAxisAlignment>(
          oldValue: old,
          newValue: mainAxisAlignment,
          set: (v) => mainAxisAlignment = v,
        );
      } else if (action == "setCrossAxisAlignment") {
        CrossAxisAlignment old = crossAxisAlignment;
        crossAxisAlignment = CrossAxisAlignment.values.firstWhere(
            (e) => e.toString() == args["crossAxisAlignment"],
            orElse: () => CrossAxisAlignment.start);
        return UpdateAction<CrossAxisAlignment>(
          oldValue: old,
          newValue: crossAxisAlignment,
          set: (v) => crossAxisAlignment = v,
        );
      } else if (action == "setSpacing") {
        Variable<double> old = spacing;
        spacing = VariableParser.parse<double>(args["spacing"]!, root,
            notifyListeners: notifyListeners);
        return UpdateAction<Variable<double>>(
          oldValue: old,
          newValue: spacing,
          set: (v) => spacing = v,
        );
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Error in handleAction: $e");
      return null;
    }
  }
}

//StackElement
@notifier
class StackElementType extends ElementContainerType {
  @notify
  AlignmentGeometry _alignment = AlignmentDirectional.topStart;
  @notify
  StackFit _fit = StackFit.loose;

  @override
  Widget getWidget(List<Widget> children) {
    return Stack(
      alignment: alignment,
      children: children,
    );
  }

  @override
  ElementContainerType clone() => StackElementType()..copy(this);

  @override
  void copy(ElementContainerType other) {
    super.copy(other);
    if (other is StackElementType) {
      alignment = other.alignment;
      fit = other.fit;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "stack",
      "alignment": alignment.toString(),
      "fit": fit.toString(),
    };
  }

  @override
  String get label => "Stack";

  @override
  UpdateAction? setValue(String property, String value, ElementRoot root) {
    switch (property) {
      case "alignment":
        var old = alignment;
        alignment = AlignmentExtension.fromString(value,
            defaultValue: Alignment.center);
        return UpdateAction<AlignmentGeometry>(
          oldValue: old,
          newValue: alignment,
          set: (v) => alignment = v,
        );
      case "fit":
        var old = fit;
        fit = StackFit.values.firstWhere((e) => e.toString() == value,
            orElse: () => StackFit.loose);
        return UpdateAction<StackFit>(
          oldValue: old,
          newValue: fit,
          set: (v) => fit = v,
        );
    }
    return null;
  }

  @override
  UpdateAction? handleAction(String action, Map<String, String> args) => null;
}

//WrapElement
@notifier
class WrapElementType extends ElementContainerType {
  @notify
  Axis _direction = Axis.horizontal;
  @notify
  WrapAlignment _alignment = WrapAlignment.start;
  @notify
  double _spacing = 0;
  @notify
  WrapCrossAlignment _crossAxisAlignment = WrapCrossAlignment.start;
  @notify
  TextDirection _textDirection = TextDirection.ltr;
  @notify
  VerticalDirection _verticalDirection = VerticalDirection.down;
  @notify
  Clip _clipBehavior = Clip.none;

  @override
  Widget getWidget(List<Widget> children) {
    return Wrap(
      direction: direction,
      alignment: alignment,
      spacing: spacing,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      clipBehavior: clipBehavior,
      children: children,
    );
  }

  @override
  ElementContainerType clone() => WrapElementType()..copy(this);

  @override
  void copy(ElementContainerType other) {
    super.copy(other);
    if (other is WrapElementType) {
      direction = other.direction;
      alignment = other.alignment;
      spacing = other.spacing;
      crossAxisAlignment = other.crossAxisAlignment;
      textDirection = other.textDirection;
      verticalDirection = other.verticalDirection;
      clipBehavior = other.clipBehavior;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "wrap",
      "direction": direction.toString(),
      "alignment": alignment.toString(),
      "spacing": spacing.toString(),
      "crossAxisAlignment": crossAxisAlignment.toString(),
      "textDirection": textDirection.toString(),
      "verticalDirection": verticalDirection.toString(),
      "clipBehavior": clipBehavior.toString(),
    };
  }

  @override
  String get label => "Wrap";

  @override
  UpdateAction? setValue(String property, String value, ElementRoot root) {
    switch (property) {
      case "direction":
        var old = direction;
        direction = value == "horizontal" ? Axis.horizontal : Axis.vertical;
        return UpdateAction<Axis>(
          oldValue: old,
          newValue: direction,
          set: (v) => direction = v,
        );
      case "alignment":
        var old = alignment;
        alignment = WrapAlignment.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => WrapAlignment.start);
        return UpdateAction<WrapAlignment>(
          oldValue: old,
          newValue: alignment,
          set: (v) => alignment = v,
        );
      case "spacing":
        var old = spacing;
        spacing = double.tryParse(value) ?? 0;
        return UpdateAction<double>(
          oldValue: old,
          newValue: spacing,
          set: (v) => spacing = v,
        );
      case "crossAxisAlignment":
        var old = crossAxisAlignment;
        crossAxisAlignment = WrapCrossAlignment.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => WrapCrossAlignment.start);
        return UpdateAction<WrapCrossAlignment>(
          oldValue: old,
          newValue: crossAxisAlignment,
          set: (v) => crossAxisAlignment = v,
        );
      case "textDirection":
        var old = textDirection;
        textDirection = TextDirection.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => TextDirection.ltr);
        return UpdateAction<TextDirection>(
          oldValue: old,
          newValue: textDirection,
          set: (v) => textDirection = v,
        );
      case "verticalDirection":
        var old = verticalDirection;
        verticalDirection = VerticalDirection.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => VerticalDirection.down);
        return UpdateAction<VerticalDirection>(
          oldValue: old,
          newValue: verticalDirection,
          set: (v) => verticalDirection = v,
        );
      case "clipBehavior":
        var old = clipBehavior;
        clipBehavior = Clip.values
            .firstWhere((e) => e.toString() == value, orElse: () => Clip.none);
        return UpdateAction<Clip>(
          oldValue: old,
          newValue: clipBehavior,
          set: (v) => clipBehavior = v,
        );
    }
    return null;
  }

  @override
  UpdateAction? handleAction(String action, Map<String, String> args) {
    return null;
  }
}

@notifier
class ScrollableGridElementType extends ElementContainerType {
  @notify
  int _crossAxisCount;

  @notify
  double _crossAxisSpacing = 0;
  @notify
  double _mainAxisSpacing = 0;
  @notify
  double _childAspectRatio = 1;
  @notify
  MainAxisAlignment _mainAxisAlignment = MainAxisAlignment.start;
  @notify
  CrossAxisAlignment _crossAxisAlignment = CrossAxisAlignment.start;
  @notify
  Axis _direction = Axis.vertical;
  @notify
  bool _canScroll = false;

  ScrollableGridElementType({
    required int crossAxisCount,
  }) : _crossAxisCount = crossAxisCount;

  @override
  Widget getWidget(List<Widget> children) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
      scrollDirection: direction,
      physics: canScroll ? null : const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  @override
  ElementContainerType clone() =>
      ScrollableGridElementType(crossAxisCount: crossAxisCount)..copy(this);

  @override
  void copy(ElementContainerType other) {
    super.copy(other);
    if (other is ScrollableGridElementType) {
      crossAxisCount = other.crossAxisCount;
      crossAxisSpacing = other.crossAxisSpacing;
      mainAxisSpacing = other.mainAxisSpacing;
      childAspectRatio = other.childAspectRatio;
      mainAxisAlignment = other.mainAxisAlignment;
      crossAxisAlignment = other.crossAxisAlignment;
      direction = other.direction;
      canScroll = other.canScroll;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "scrollableGrid",
      "crossAxisCount": crossAxisCount,
      "crossAxisSpacing": crossAxisSpacing,
      "mainAxisSpacing": mainAxisSpacing,
      "childAspectRatio": childAspectRatio,
      "mainAxisAlignment": mainAxisAlignment.toString(),
      "crossAxisAlignment": crossAxisAlignment.toString(),
      "direction": direction.toString(),
      "canScroll": canScroll,
    };
  }

  @override
  String get label => "Grid";

  @override
  UpdateAction? setValue(String property, String value, ElementRoot root) {
    switch (property) {
      case "crossAxisCount":
        var old = crossAxisCount;
        crossAxisCount = int.tryParse(value) ?? crossAxisCount;
        return UpdateAction<int>(
          oldValue: old,
          newValue: crossAxisCount,
          set: (v) => crossAxisCount = v,
        );
      case "crossAxisSpacing":
        var old = crossAxisSpacing;
        crossAxisSpacing = double.tryParse(value) ?? crossAxisSpacing;
        return UpdateAction<double>(
          oldValue: old,
          newValue: crossAxisSpacing,
          set: (v) => crossAxisSpacing = v,
        );
      case "mainAxisSpacing":
        var old = mainAxisSpacing;
        mainAxisSpacing = double.tryParse(value) ?? mainAxisSpacing;
        return UpdateAction<double>(
          oldValue: old,
          newValue: mainAxisSpacing,
          set: (v) => mainAxisSpacing = v,
        );
      case "childAspectRatio":
        var old = childAspectRatio;
        childAspectRatio = double.tryParse(value) ?? childAspectRatio;
        return UpdateAction<double>(
          oldValue: old,
          newValue: childAspectRatio,
          set: (v) => childAspectRatio = v,
        );
      case "mainAxisAlignment":
        var old = mainAxisAlignment;
        mainAxisAlignment = MainAxisAlignment.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => MainAxisAlignment.start);
        return UpdateAction<MainAxisAlignment>(
          oldValue: old,
          newValue: mainAxisAlignment,
          set: (v) => mainAxisAlignment = v,
        );
      case "crossAxisAlignment":
        var old = crossAxisAlignment;
        crossAxisAlignment = CrossAxisAlignment.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => CrossAxisAlignment.start);
        return UpdateAction<CrossAxisAlignment>(
          oldValue: old,
          newValue: crossAxisAlignment,
          set: (v) => crossAxisAlignment = v,
        );
      case "direction":
        var old = direction;
        direction = value == "vertical" ? Axis.vertical : Axis.horizontal;
        return UpdateAction<Axis>(
          oldValue: old,
          newValue: direction,
          set: (v) => direction = v,
        );
      case "canScroll":
        var old = canScroll;
        canScroll = value.toLowerCase() == "true";
        return UpdateAction<bool>(
          oldValue: old,
          newValue: canScroll,
          set: (v) => canScroll = v,
        );
    }
    return null;
  }

  @override
  UpdateAction? handleAction(String action, Map<String, String> args) {
    return null;
  }
}

@notifier
class ScalingGridElementType extends ElementContainerType {
  @notify
  WrapAlignment _alignment = WrapAlignment.start;
  @notify
  double _spacing = 0;
  @notify
  WrapCrossAlignment _crossAxisAlignment = WrapCrossAlignment.start;

  ScalingGridElementType({
    WrapAlignment alignment = WrapAlignment.start,
    double spacing = 0,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
  })  : _alignment = alignment,
        _spacing = spacing,
        _crossAxisAlignment = crossAxisAlignment;

  @override
  Widget getWidget(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      double ratio = constraints.maxWidth / constraints.maxHeight;
      if (ratio < 1) ratio = ratio - 1;

      double squareRoot = sqrt(children.length + ratio);
      int crossAxisCount = ratio > 1 ? squareRoot.ceil() : squareRoot.floor();

      double width = (constraints.maxWidth / crossAxisCount);
      double height =
          constraints.maxHeight / (children.length / crossAxisCount);
      return Wrap(
        alignment: alignment,
        spacing: spacing,
        crossAxisAlignment: crossAxisAlignment,
        children: children
            .map((e) => SizedBox(width: width, height: height, child: e))
            .toList(),
      );
    });
  }

  @override
  ElementContainerType clone() => ScalingGridElementType()..copy(this);

  @override
  void copy(ElementContainerType other) {
    super.copy(other);
    if (other is ScalingGridElementType) {
      alignment = other.alignment;
      spacing = other.spacing;
      crossAxisAlignment = other.crossAxisAlignment;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "scalingGrid",
      "alignment": alignment.toString(),
      "spacing": spacing.toString(),
      "crossAxisAlignment": crossAxisAlignment.toString(),
    };
  }

  ScalingGridElementType.fromJson(Map<String, dynamic> json) {
    String? alignmentString = json["alignment"];
    for (WrapAlignment value in WrapAlignment.values) {
      if (value.toString() == alignmentString) {
        alignment = value;
        break;
      }
    }

    String? crossAxisString = json["crossAxisAlignment"];
    for (WrapCrossAlignment value in WrapCrossAlignment.values) {
      if (value.toString() == crossAxisString) {
        crossAxisAlignment = value;
        break;
      }
    }

    spacing = double.tryParse(json["spacing"]) ?? 0;
  }

  @override
  UpdateAction? setValue(String property, String value, ElementRoot root) {
    switch (property) {
      case "alignment":
        var old = alignment;
        alignment = WrapAlignment.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => WrapAlignment.start);
        return UpdateAction<WrapAlignment>(
          oldValue: old,
          newValue: alignment,
          set: (v) => alignment = v,
        );
      case "spacing":
        var old = spacing;
        spacing = double.tryParse(value) ?? 0;
        return UpdateAction<double>(
          oldValue: old,
          newValue: spacing,
          set: (v) => spacing = v,
        );
      case "crossAxisAlignment":
        var old = crossAxisAlignment;
        crossAxisAlignment = WrapCrossAlignment.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => WrapCrossAlignment.start);
        return UpdateAction<WrapCrossAlignment>(
          oldValue: old,
          newValue: crossAxisAlignment,
          set: (v) => crossAxisAlignment = v,
        );
    }
    return null;
  }

  @override
  UpdateAction? handleAction(String action, Map<String, String> args) => null;

  @override
  String get label => "Scaling Grid";
}
