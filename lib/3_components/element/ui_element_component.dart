import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/3_components/layout/dynamic_decoration.dart';
import 'package:jouhakka_forge/3_components/layout/dynamic_padding.dart';
import 'package:jouhakka_forge/4_views/page_design_view.dart';

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
  })  : assert(overrideContent == null || element is BranchElement,
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
    if (element.size.width is AutomaticSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = widget.globalKey.currentContext;
        if (context != null) {
          final size = context.size;
          if (size != null && size.width != element.size.width.renderValue) {
            (element.size.width as AutomaticSize).renderValue = size.width;
          }
        }
      });
    }

    if (element.size.height is AutomaticSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = widget.globalKey.currentContext;
        if (context != null) {
          final size = context.size;
          if (size != null && size.height != element.size.height.renderValue) {
            (element.size.height as AutomaticSize).renderValue = size.height;
          }
        }
      });
    }

    Widget? current = widget.overrideContent ?? element.getContent();

    ElementContainer? container = element.tryGetContainer();
    if (container != null && container.type is FlexElementType) {
      debugPrint("FlexElementType applied in ${element.id}");
      FlexElementType flex = container.type as FlexElementType;
      if (flex.crossAxisAlignment == CrossAxisAlignment.stretch) {
        if (flex.direction == Axis.vertical &&
            element.size.width is ShrinkingSize) {
          current = IntrinsicWidth(child: current);
        } else if (flex.direction == Axis.horizontal &&
            element.size.height is ShrinkingSize) {
          current = IntrinsicHeight(child: current);
          debugPrint("IntrinsicHeight applied in ${element.id}");
        }
      }
    }

    if (container != null &&
        container.overflow != ContentOverflow.allow &&
        container.overflow != ContentOverflow.clip) {
      if (container.overflow == ContentOverflow.allow) {
        current = OverflowBox(
          fit: OverflowBoxFit.max,
          alignment: container.type is SingleChildElementType
              ? (container.type as SingleChildElementType).alignment
              : Alignment.center,
          child: current,
        );
      } else if (container.overflow == ContentOverflow.clip) {
        current = ClipRect(child: current);
      } else if (container.overflow == ContentOverflow.verticalScroll ||
          container.overflow == ContentOverflow.horizontalScroll) {
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
              scrollDirection:
                  container.overflow == ContentOverflow.verticalScroll
                      ? Axis.vertical
                      : Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              restorationId: hashCode.toString(),
              child: current,
            ),
          );
        } catch (e, s) {
          debugPrint("Error in SingleChildScrollView: $e $s");
        }
      }
    }

    BoxConstraints? constraints;
    bool constrainedWidth = element.size.width is AutomaticSize &&
        (element.size.width as AutomaticSize).constrained;
    bool constrainedHeight = element.size.height is AutomaticSize &&
        (element.size.height as AutomaticSize).constrained;
    if (element.size.isConstrained()) {
      constraints = BoxConstraints(
        minWidth: constrainedWidth
            ? (element.size.width as AutomaticSize).min.value
            : 0,
        maxWidth: constrainedWidth
            ? (element.size.width as AutomaticSize).max.value
            : double.infinity,
        minHeight: constrainedHeight
            ? (element.size.height as AutomaticSize).min.value
            : 0,
        maxHeight: constrainedHeight
            ? (element.size.height as AutomaticSize).max.value
            : double.infinity,
      );
    }

    double? width = widget.element.size.constantWidth;
    double? height = widget.element.size.constantHeight;

    if (current != null && widget.canApplyInfinity) {
      if (element.size.width is ExpandingSize) {
        width = double.infinity;
        debugPrint("Width is expanded in ${element.id}");
      }
      if (element.size.height is ExpandingSize) {
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

    if (container != null && current != null) {
      if (widget.dynamicPadding) {
        double extraPadding = sqrt(min(element.size.width.renderValue ?? 20,
            element.size.height.renderValue ?? 20));
        current = DynamicPadding(
          padding: container.padding.padding,
          extraPadding: extraPadding,
          child: current,
        );
      } else if (container.padding.padding != EdgeInsets.zero) {
        current = Padding(padding: container.padding.padding, child: current);
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
              borderRadius: decoration.radius.borderRadius,
              border: decoration.border.value?.boxBorder,
            ),
            child: current,
          );

          /*if (decoration.margin.value != null) {
            current =
                Padding(padding: decoration.margin.value!, child: current);
          }*/
        },
        orElse: () {
          if (current != null) {
            current = DynamicDecoration(child: current!);
          }
        },
      );
    }

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
