import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';

class InteractiveCanvas extends StatefulWidget {
  final Resolution resolution;
  final Widget child;
  final double padding;
  final double minScale;
  final double maxScale;

  const InteractiveCanvas(
      {super.key,
      required this.resolution,
      required this.child,
      this.padding = 16,
      this.minScale = 0.1,
      this.maxScale = 20.0});

  @override
  State<InteractiveCanvas> createState() => _InteractiveCanvasState();
}

class _InteractiveCanvasState extends State<InteractiveCanvas> {
  Resolution get resolution => widget.resolution;
  late TransformationController controller;

  @override
  void initState() {
    controller = TransformationController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      Size size = _calculateSize(constraints);

      fitToView(size, constraints);

      return InteractiveViewer(
        transformationController: controller,
        minScale: 0.1,
        maxScale: 20.0,
        constrained: false,
        onInteractionUpdate: (details) {},
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Center(
            child: widget.child,
          ),
        ),
      );
    });
  }

  Size _calculateSize(BoxConstraints constraints) {
    double viewWidth = constraints.maxWidth;
    double viewHeight = constraints.maxHeight;
    double width = viewWidth;
    double height = viewHeight;
    double ratio = resolution.ratio;
    double padding = widget.padding;

    if (ratio > 1 && resolution.width > viewWidth) {
      width = resolution.width;
      height = resolution.width / ratio;
      double scaleToConstraints = height - viewHeight;
      if (scaleToConstraints > 0) {
        width += scaleToConstraints;
      }
      height += padding * 2;
      width += padding * 2;
    } else if (ratio <= 1 && resolution.height > viewHeight) {
      height = resolution.height + padding * 2;
      double scaleToConstraints = height / viewHeight;
      width *= scaleToConstraints;
    }

    return Size(width, height);
  }

  void fitToView(Size canvasSize, BoxConstraints viewSize) {
    double scale = min(viewSize.maxWidth / canvasSize.width,
        viewSize.maxHeight / canvasSize.height);
    controller.value = Matrix4.identity()..scale(scale);
  }
}
