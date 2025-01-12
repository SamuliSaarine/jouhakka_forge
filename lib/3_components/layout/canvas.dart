import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';

class InteractiveCanvas extends StatefulWidget {
  final Resolution resolution;
  final Widget child;

  const InteractiveCanvas(
      {super.key, required this.resolution, required this.child});

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
      const double padding = 16;
      double width = constraints.maxWidth;
      double height = constraints.maxHeight;
      double ratio = resolution.ratio;

      if (ratio > 1 && resolution.width > constraints.maxWidth) {
        width = widget.resolution.width;
        height = widget.resolution.width / ratio;
        double scaleToConstraints = height - constraints.maxHeight;
        if (scaleToConstraints > 0) {
          width += scaleToConstraints;
        }
        height += padding * 2;
        width += padding * 2;
      } else if (ratio <= 1 && resolution.height > constraints.maxHeight) {
        height = widget.resolution.height + padding * 2;
        double scaleToConstraints = height / constraints.maxHeight;
        width *= scaleToConstraints;
      }

      double initialScale =
          min(constraints.maxWidth / width, constraints.maxHeight / height);

      controller.value = Matrix4.identity()..scale(initialScale);

      return InteractiveViewer(
        transformationController: controller,
        minScale: 0.1,
        maxScale: 20.0,
        constrained: false,
        onInteractionUpdate: (details) {},
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: SizedBox(
              width: widget.resolution.width,
              height: widget.resolution.height,
              child: widget.child,
            ),
          ),
        ),
      );
    });
  }
}
