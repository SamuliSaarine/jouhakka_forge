import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/1_helpers/build/annotations.dart';
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

  void addChild(UIElement child) {
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

  String get label => type.label;
}

enum ContentOverflow { allow, clip, horizontalScroll, verticalScroll }

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
}

@notifier
class SingleChildElementType extends ElementContainerType {
  @notify
  Alignment _alignment = Alignment.center;

  /// [ElementContainerType] that can only have one child.

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
  String get label => "Stack";
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
  String get label => "Wrap";
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
  String get label => "Grid";
}

@notifier
class ScalingGridElementType extends ElementContainerType {
  @notify
  WrapAlignment _alignment = WrapAlignment.start;
  @notify
  double _spacing = 0;
  @notify
  WrapCrossAlignment _crossAxisAlignment = WrapCrossAlignment.start;

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
  String get label => "Scaling Grid";
}
