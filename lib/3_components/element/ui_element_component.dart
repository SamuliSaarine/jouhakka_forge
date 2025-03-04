import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/3_components/layout/dynamic_decoration.dart';
import 'package:jouhakka_forge/3_components/layout/dynamic_padding.dart';

class ElementWidget extends StatefulWidget {
  final UIElement element;
  final bool wireframe;
  final GlobalKey globalKey;
  final Widget? overrideContent;
  final bool dynamicPadding;
  final bool canApplyInfinity;

  const ElementWidget({
    required this.element,
    required this.globalKey,
    this.wireframe = false,
    this.overrideContent,
    this.dynamicPadding = false,
    required this.canApplyInfinity,
  })  : assert(overrideContent == null || element is ElementContainer,
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
  }

  @override
  Widget build(BuildContext context) {
    if (element.width.type != SizeType.fixed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = widget.globalKey.currentContext;
        if (context != null) {
          final size = context.size;
          if (size != null && size.width != element.width.value) {
            element.width.value = size.width;
          }
        }
      });
    }

    if (element.height.type != SizeType.fixed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = widget.globalKey.currentContext;
        if (context != null) {
          final size = context.size;
          if (size != null && size.height != element.height.value) {
            element.height.value = size.height;
          }
        }
      });
    }

    Widget? current = widget.overrideContent ?? element.getContent();

    if (element is ElementContainer &&
        (element as ElementContainer).type is FlexElementType) {
      debugPrint("FlexElementType applied in ${element.id}");
      FlexElementType flex =
          (element as ElementContainer).type as FlexElementType;
      if (flex.crossAxisAlignment == CrossAxisAlignment.stretch) {
        if (flex.direction == Axis.vertical &&
            element.width.type == SizeType.auto) {
          current = IntrinsicWidth(child: current);
        } else if (flex.direction == Axis.horizontal &&
            element.height.type == SizeType.auto) {
          current = IntrinsicHeight(child: current);
          debugPrint("IntrinsicHeight applied in ${element.id}");
        }
      }
    }

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

    if (current != null && widget.canApplyInfinity) {
      if (element.width.type == SizeType.expand) {
        width = double.infinity;
        debugPrint("Width is expanded in ${element.id}");
      }
      if (element.height.type == SizeType.expand) {
        height = double.infinity;
        debugPrint("Height is expanded in ${element.id}");
      }
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

    ElementContainer? container = element.tryGetContainer();
    if (container != null && current != null) {
      if (widget.dynamicPadding) {
        double extraPadding =
            sqrt(min(element.width.value ?? 20, element.height.value ?? 20));
        current = DynamicPadding(
          padding: container.padding,
          extraPadding: extraPadding,
          child: current,
        );
      } else if (container.padding != EdgeInsets.zero) {
        current = Padding(padding: container.padding, child: current);
      }
    }

    if (element is BranchElement) {
      (element as BranchElement).decoration.ifValue(
        (decoration) {
          Color? backgroundColor = decoration.backgroundColor.value;
          current = DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor == Colors.transparent
                  ? null
                  : backgroundColor,
              borderRadius: BorderRadius.circular(decoration.radius.value),
              border: decoration.borderColor.value == Colors.transparent ||
                      decoration.borderWidth.value == 0
                  ? null
                  : Border.all(
                      color: decoration.borderColor.value,
                      width: decoration.borderWidth.value,
                    ),
            ),
            child: current,
          );

          if (decoration.margin.value != null) {
            current =
                Padding(padding: decoration.margin.value!, child: current);
          }
        },
        orElse: () {
          if (current != null) {
            current = DynamicDecoration(child: current!);
          }
        },
      );
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
