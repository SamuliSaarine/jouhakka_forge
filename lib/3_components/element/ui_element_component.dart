import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jouhakka_forge/0_models/container_element.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';

class ElementWidget extends StatefulWidget {
  final UIElement element;
  final bool wireframe;
  final GlobalKey globalKey;
  final Widget? overrideContent;

  const ElementWidget(
      {required this.element,
      required this.globalKey,
      this.wireframe = false,
      this.overrideContent})
      : assert(overrideContent == null || element is ContainerElement,
            "Only container elements content can be overridden"),
        super(key: globalKey);

  @override
  State<ElementWidget> createState() => _ElementWidgetState();
}

class _ElementWidgetState extends State<ElementWidget> {
  UIElement get element => widget.element;

  @override
  void initState() {
    super.initState();

    if (widget.element.width.type == SizeType.fixed) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = widget.globalKey.currentContext;
      if (context != null) {
        final size = context.size;
        if (size != null) {
          widget.element.width.value = size.width;
          widget.element.height.value = size.height;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? current = widget.overrideContent ?? widget.element.getContent();

    BoxConstraints? constraints =
        (element.width.constraints() || element.height.constraints())
            ? BoxConstraints(
                minWidth: element.width.minPixels ?? 0,
                maxWidth: element.width.maxPixels ?? double.infinity,
                minHeight: element.height.minPixels ?? 0,
                maxHeight: element.height.maxPixels ?? double.infinity,
              )
            : null;

    double? width = widget.element.width.tryGetFixed();
    double? height = widget.element.height.tryGetFixed();

    if (current != null && (width == null || height == null)) {
      debugPrint("Element ${element.hashCode} has null width or height");
    }

    constraints = (width != null || height != null)
        ? constraints?.tighten(width: width, height: height) ??
            BoxConstraints.tightFor(width: width, height: height)
        : constraints;
    if (current == null && (constraints == null || !constraints.isTight)) {
      current = LimitedBox(
        maxWidth: 0.0,
        maxHeight: 0.0,
        child: ConstrainedBox(constraints: const BoxConstraints.expand()),
      );
    } /*else if (alignment != null) {
      current = Align(alignment: alignment!, child: current);
    }*/

    if (element.padding != null) {
      current = Padding(padding: element.padding!, child: current);
    }

    if (element.decoration != null) {
      ElementDecoration decoration = element.decoration!;
      current = DecoratedBox(
        decoration: BoxDecoration(
          color: decoration.getBackgroundColor(),
          borderRadius: BorderRadius.circular(decoration.getRadius()),
          border: decoration.getBorderWidth() == 0
              ? null
              : Border.all(
                  color: decoration.getBorderColor(),
                  width: decoration.getBorderWidth(),
                ),
        ),
        child: current,
      );

      if (decoration.margin != null) {
        current = Padding(padding: decoration.margin!, child: current);
      }
    }

    /*if (clipBehavior != Clip.none) {
      assert(decoration != null);
      current = ClipPath(
        clipper: _DecorationClipper(
          textDirection: Directionality.maybeOf(context),
          decoration: decoration!,
        ),
        clipBehavior: clipBehavior,
        child: current,
      );
    }*/

    if (constraints != null) {
      current = ConstrainedBox(constraints: constraints, child: current);
    }

    /*if (transform != null) {
      current = Transform(
          transform: transform!, alignment: transformAlignment, child: current);
    }*/

    /*if (element.width.type != SizeType.expand &&
        element.height.type != SizeType.expand) {
      current = OverflowBox(
        fit: OverflowBoxFit.deferToChild,
        child: current,
      );
    }*/

    return current!;
  }
}

extension WidgetExtension on UIElement {
  Widget widget() {
    Widget? component;
    component = getContent();

    if (width.type == SizeType.expand || height.type == SizeType.expand) {
      if (insideColumnOrRow()) {
        component =
            component != null ? Expanded(child: component) : const Spacer();
      }
    }
    return component!;
  }

  Widget wireframe({bool wrappedToInterface = false}) {
    Widget? component;
    component = getContentAsWireframe();

    component = Container(
      width: width.tryGetFixed(),
      height: height.tryGetFixed(),
      decoration: decoration == null
          ? _wireframeEmptyDecoration()
          : _wireframeDecoration(),
      child: component,
    );

    return component;
  }

  BoxDecoration _wireframeDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black, width: 1),
    );
  }

  BoxDecoration _wireframeEmptyDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.blue, width: 0.5),
    );
  }

  bool insideColumnOrRow() {
    if (parent == null) {
      return false;
    }
    if (parent! is! ContainerElement) {
      return false;
    }
    return (parent! as ContainerElement).type is FlexElementType;
  }
}
