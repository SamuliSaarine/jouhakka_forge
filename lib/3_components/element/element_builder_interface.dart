import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/layout/context_menu.dart';
import 'package:jouhakka_forge/3_components/layout/context_popup.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:jouhakka_forge/3_components/element/ui_element_component.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

part 'element_builder_interface_extension.dart';

class ElementBuilderInterface extends StatefulWidget {
  final void Function(UIElement element, int index) onBodyChanged;

  final UIElement element;
  final int index;
  final bool expandStack;

  /// - Null means that there will be no scaling box.
  /// - CenterRight means vertical scaling.
  /// - BottomCenter means horizontal scaling.
  /// - BottomRight keeps ratio when scaling.
  final Alignment? scaleAlignment;

  const ElementBuilderInterface({
    required GlobalKey globalKey,
    required this.element,
    this.index = 0,
    required this.onBodyChanged,
    this.scaleAlignment,
    this.expandStack = false,
  }) : super(key: globalKey);

  @override
  State<ElementBuilderInterface> createState() {
    return _ElementBuilderInterfaceState();
  }
}

class _ElementBuilderInterfaceState extends State<ElementBuilderInterface> {
  UIElement get element => widget.element;
  late GlobalKey globalKey;
  final List<GlobalKey> childKeys = [];
  bool _isSelected = false;
  bool _isHovering = false;
  late SizeType _lastWidthType;
  late SizeType _lastHeightType;

  @override
  void initState() {
    globalKey = GlobalKey();
    elementInit();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ElementBuilderInterface oldWidget) {
    super.didUpdateWidget(oldWidget);

    //If the source has changed, reattach the listener to the new source
    if (widget.element != oldWidget.element) {
      elementDispose();
      elementInit();
    }
  }

  @override
  void dispose() {
    elementDispose();
    super.dispose();
  }

  @override
  void setState(void Function() fn) {
    super.setState(fn);
  }

  void elementInit() {
    if (element is ContainerElement) {
      ContainerElement containerElement = element as ContainerElement;
      for (int i = 0; i < containerElement.children.length; i++) {
        childKeys.add(GlobalKey());
      }
      (element as ContainerElement).childNotifier.addListener(() {
        setState(() {});
      });
    }

    _lastWidthType = element.width.type;
    _lastHeightType = element.height.type;
    element.addListener(updateOnChange);
  }

  void elementDispose() {
    element.removeListener(updateOnChange);
    if (element is ContainerElement) {
      childKeys.clear();
      (element as ContainerElement).childNotifier.removeListener(() {
        setState(() {});
      });
    }
  }

  void updateOnChange() {
    if (element.width.type != _lastWidthType ||
        element.height.type != _lastHeightType) {
      _lastWidthType = element.width.type;
      _lastHeightType = element.height.type;
      widget.onBodyChanged(element, widget.index);
    } else {
      //debugPrint("Setting state on change");
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    //return ChangeListener<UIElement>(
    //source: element,
    // builder: () {

    Widget? contentOverride = element is ContainerElement
        ? _containerOverride(element as ContainerElement)
        : null;

    try {
      Widget current = ElementWidget(
        element: element,
        globalKey: globalKey,
        wireframe: true,
        canApplyInfinity: element.parent != null &&
            element.parent!.type is SingleChildElementType,
        overrideContent: contentOverride,
        dynamicPadding: true,
      );

      try {
        return SizedBox(
          width: element.width.tryGetFixed(),
          height: element.height.tryGetFixed(),
          child: ClickDetector(
            opaque: true,
            onPointerEvent: _onPointerEvent,
            primaryActionUp: _primaryAction,
            secondaryActionDown: _secondaryAction,
            child: Stack(
              clipBehavior: Clip.none,
              fit: widget.expandStack ? StackFit.expand : StackFit.loose,
              children: [
                current,
                _editors(contentOverride != null),
              ],
            ),
          ),
        );
      } catch (e) {
        debugPrint("Error in build: $e");
        rethrow;
      }
    } catch (e) {
      debugPrint("Error: $e");
      rethrow;
    }
  }

  Widget _editors(bool contentOverridden) {
    return Positioned.fill(
      child: SizedBox(
        width: element.width.value,
        height: element.height.value,
        child: ValueListener(
          source: Session.hoveredElement,
          condition: (value) {
            return _isHovering != (value == element);
          },
          builder: (hoveringElement) {
            _isHovering = hoveringElement == element;
            return ValueListener(
              source: Session.selectedElement,
              condition: (value) {
                return _isSelected != (value == element);
              },
              builder: (selectedElement) {
                _isSelected = selectedElement == element;
                bool showEditor = _isSelected || _isHovering;
                return Stack(
                  fit: StackFit.loose,
                  children: showEditor
                      ? [
                          //..._elementInterface(!contentOverridden),
                          SizedBox.expand(
                            child: IgnorePointer(
                                child: DecoratedBox(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.green, width: 1),
                              ),
                            )),
                          ),
                          if (widget.scaleAlignment != null) _scaleBox(),
                        ]
                      : [],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _scaleBox() {
    Alignment alignment = widget.scaleAlignment!;
    double size =
        sqrt(min(element.width.value ?? 400, element.height.value ?? 400));
    //debugPrint("Size: $size | ${alignment.ratio}");
    return Align(
      alignment: alignment,
      child: MouseRegion(
        cursor: alignment.getScaleCursor(),
        child: GestureDetector(
          onPanStart: (details) {
            if (!_isSelected) {
              Session.selectedElement.value = element;
            }
            debugPrint("Changing cursor");
            Session.hoverLocked = true;
            Session.globalCursor.value = alignment.getScaleCursor();
          },
          onPanUpdate: (details) {
            Offset localDelta =
                details.delta * Session.zoom.clamp(1, 3); // / 2 + 0.5);
            if (alignment != Alignment.centerRight) {
              if ((element.height.value ?? 2) < 1 && localDelta.dy < 0) {
                debugPrint("Height too small");
                return;
              }

              element.height.add(localDelta.dy.ceilToDouble());
            }

            if (alignment == Alignment.bottomCenter) {
              return;
            }

            if ((element.width.value ?? 2) < 1 && localDelta.dx < 0) {
              debugPrint("Width too small");
              return;
            }

            element.width.add(localDelta.dx.roundToDouble());
          },
          onPanEnd: (details) {
            debugPrint("Resetting cursor");

            Session.hoveredElement.value = null;
            Session.hoverLocked = false;
            Session.globalCursor.value = MouseCursor.defer;
          },
          onPanCancel: () {
            debugPrint("Pan cancelled");

            Session.hoveredElement.value = null;
            Session.hoverLocked = false;
            Session.globalCursor.value = MouseCursor.defer;
          },
          child: Container(
            color: Colors.blue,
            height: size * alignment.ratio,
            width: size / alignment.ratio,
          ),
        ),
      ),
    );
  }
}
