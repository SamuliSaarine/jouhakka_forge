import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/layout/my_interactive_viewer.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

// Requirements:
// - The view should be interactive and allow zooming and panning.
// - Zooming is happening only if left ctrl is pressed. (Flutter transforms scroll to zoom when ctrl is pressed)
// - If control is not pressed, scrolling should pan the view and shift + scroll should pan the view horizontally.
// - Bounds, for zoom out and panning, is determined by the canvas size and the view size and minScale.
// - Min scale tells how much the canvas can be zoomed out and how much is the minimum space around canvas when totally zoomed out.
//   -> For example, if minScale is 0.5, the minimum space around the canvas is the view size.
// - The canvas should be centered in the view.
// - The view should be colored.
// - The view cannot be smaller than available space.

class InteractiveCanvasView extends StatefulWidget {
  final Resolution canvasResolution;
  final Widget canvasObject;
  final double minScale;
  final double maxScale;
  final void Function()? onViewTap;
  final bool scrollEnabled;

  const InteractiveCanvasView({
    super.key,
    required this.canvasResolution,
    required this.canvasObject,
    this.minScale = 0.5,
    this.maxScale = 20.0,
    this.onViewTap,
    this.scrollEnabled = false,
  });

  @override
  State<InteractiveCanvasView> createState() => _InteractiveCanvasViewState();
}

class _InteractiveCanvasViewState extends State<InteractiveCanvasView> {
  Resolution get resolution => widget.canvasResolution;
  TransformationController? _transformationController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(builder: (context, constraints) {
        Size size = _calculateSize(constraints);
        double scale = fitToView(size, constraints);

        if (_transformationController == null) {
          _transformationController = TransformationController();
          _transformationController!.value = Matrix4.identity()
            ..translate(resolution.width * scale, 0)
            ..scale(scale);
          _transformationController!.addListener(() {
            Session.zoom = _transformationController!.value.getMaxScaleOnAxis();
          });
          /*_transformationController!.addListener(() {
            debugPrint(
                "Transform: ${_transformationController!.value.getTranslation()}. Scale: ${_transformationController!.value.getMaxScaleOnAxis()}");
          });*/
        }

        return DecoratedBox(
          decoration: const BoxDecoration(color: MyColors.mintgray),
          child: GestureDetector(
            onTap: () {
              debugPrint("Canvas Tapped");
              widget.onViewTap?.call();
            },
            child: MyInteractiveViewer(
              boundaryMargin: EdgeInsets.all(
                  max(resolution.width, resolution.height) /
                      2 /
                      widget.minScale),
              minScale: widget.minScale * scale,
              maxScale: 8,
              scaleEnabled: true,
              scrollEnabled: !Session.scrollEditor,
              transformationController: _transformationController,
              scaleFactor: kDefaultMouseScrollToScaleFactor,
              constrained: false,
              onInteractionUpdate: (details) {},
              child: Center(child: widget.canvasObject),
            ),
          ),
        );
      }),
    );
    //InteractiveViewer
  }

  Size _calculateSize(BoxConstraints constraints) {
    double viewWidth = constraints.maxWidth;
    double viewHeight = constraints.maxHeight;
    double width = viewWidth;
    double height = viewHeight;
    double ratio = resolution.ratio;

    if (ratio > 1 && resolution.width > viewWidth) {
      width = resolution.width;
      height = resolution.height * (width / viewWidth);
      double scaleToConstraints = height - viewHeight;
      if (scaleToConstraints > 0) {
        width += scaleToConstraints;
      }
    } else if (ratio <= 1 && resolution.height > viewHeight) {
      height = resolution.height;
      double scaleToConstraints = height / viewHeight;
      width *= scaleToConstraints;
    }

    return Size(width, height);
  }

  double fitToView(Size canvasSize, BoxConstraints viewSize) {
    return min(viewSize.maxWidth / canvasSize.width,
        viewSize.maxHeight / canvasSize.height);
  }
}

/*class _InteractiveView extends StatefulWidget {
  final Widget child;
  final double initialScale;

  const _InteractiveView({
    this.initialScale = 1.0,
    required this.child,
  });

  @override
  State<_InteractiveView> createState() => __InteractiveViewState();
}

class __InteractiveViewState extends State<_InteractiveView> {
  late GlobalKey _canvasKey;
  final TransformationController _transformer = TransformationController();

  @override
  void initState() {
    super.initState();
    _canvasKey = GlobalKey();
    _transformer.value = Matrix4.identity()..scale(widget.initialScale);
    _transformer.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
        onPointerSignal: _onPointerSignal,
        onPointerMove: _onPointerMove,
        child: ClipRect(
          child: Transform(
            transform: _transformer.value,
            alignment: Alignment.center,
            child: KeyedSubtree(key: _canvasKey, child: widget.child),
          ),
        ));
  }

  void _onPointerSignal(PointerSignalEvent event) {
    final Offset local = event.localPosition;
    final Offset global = event.position;
    final double scaleChange;
    if (event is PointerScaleEvent) {
      // The scale change factor from the event.
      double scaleChange = event.scale;
      // The cursor position in the local coordinate space.
      Offset localCursorPos = event.localPosition;

      // Calculate the new scale with clamping
      double newScale = (_scale * scaleChange).clamp(widget.initialScale, 20.0);

      // Calculate the focal point relative to the current scale
      Offset focalPointBefore = (localCursorPos - _position) / _scale;

      // Apply the new scale
      _scale = newScale;

      // Calculate the focal point after scaling
      Offset focalPointAfter = (localCursorPos - _position) / _scale;

      // To zoom towards the cursor, adjust the position by the difference in focal points
      setState(() {
        _position += (focalPointBefore - focalPointAfter) * _scale;
      });
    } else if (event is PointerScrollEvent) {
      final Offset localDelta = PointerEvent.transformDeltaViaPositions(
        untransformedEndPosition: global + event.scrollDelta,
        untransformedDelta: event.scrollDelta,
        transform: event.transform,
      );

      final Offset focalPointScene = _transformer.toScene(local);
      final Offset newFocalPointScene =
          _transformer.toScene(local - localDelta);

      _transformer.value = _matrixTranslate(
        _transformer.value,
        newFocalPointScene - focalPointScene,
      );

      /*Offset delta = event.scrollDelta;
      if (event.kind == PointerDeviceKind.mouse) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          delta = Offset(delta.dy, delta.dx);
        }
      }

      setState(() => );*/
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kMiddleMouseButton) {
      setState(() {
        _position += event.delta;
      });
    }
  }
}*/
