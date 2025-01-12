import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/container_element.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';

class ElementWidget extends StatefulWidget {
  final UIElement element;
  final bool wireframe;
  final GlobalKey globalKey;

  const ElementWidget(
      {required this.element, required this.globalKey, this.wireframe = false})
      : super(key: globalKey);

  @override
  State<ElementWidget> createState() => _ElementWidgetState();
}

class _ElementWidgetState extends State<ElementWidget> {
  bool isWireframe = false;

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
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

extension WidgetExtension on UIElement {
  Widget widget() {
    Widget? component;
    component = getContent();

    if (decoration != null) {
      component = Container(
          width: width.tryGetFixed(),
          height: height.tryGetFixed(),
          decoration: BoxDecoration(
            color: decoration!.getBackgroundColor(),
            borderRadius: BorderRadius.circular(decoration!.getRadius()),
            border: decoration!.getBorderWidth() == 0
                ? null
                : Border.all(
                    color: decoration!.getBorderColor(),
                    width: decoration!.getBorderWidth(),
                  ),
          ),
          padding: padding,
          margin: decoration?.margin,
          child: component);
    } else {
      if (padding != null) {
        component = Padding(padding: padding!, child: component);
      }

      if (width.type == SizeType.fixed || height.type == SizeType.fixed) {
        component = SizedBox(
          width: width.tryGetFixed(),
          height: height.tryGetFixed(),
          child: component,
        );
      }
    }

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

    /*if (width.type == SizeType.expand || height.type == SizeType.expand) {
      if (insideColumnOrRow()) {
        if (wrappedToInterface) {
          component = Positioned.fill(child: component);
        } else {
          //component = Expanded(child: component);
        }
      }
    }*/

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
    return (parent! as ContainerElement).type is ColumnElementType ||
        (parent! as ContainerElement).type is RowElementType;
  }
}
