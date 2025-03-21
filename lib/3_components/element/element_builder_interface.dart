import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/1_helpers/element_helper.dart';
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
  final Map<String, GlobalKey> childKeys = {};
  bool _isSelected = false;
  bool _isHovering = false;
  late Type _lastWidthType;
  late Type _lastHeightType;

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
    initElementContainer();
    if (element is BranchElement) {
      (element as BranchElement)
          .content
          .hasValueNotifier
          .addListener(initElementContainer);
    }

    _lastWidthType = element.size.width.runtimeType;
    _lastHeightType = element.size.height.runtimeType;
    element.addListener(updateOnChange);
  }

  void initElementContainer() {
    ElementContainer? container = element.tryGetContainer();
    if (container != null) {
      for (var e in container.children) {
        childKeys[e.id] = GlobalKey();
      }
      container.childNotifier.addListener(_onChildrenChanged);
    } else {
      childKeys.clear();
    }
  }

  void elementDispose() {
    element.removeListener(updateOnChange);
    if (element is BranchElement) {
      (element as BranchElement)
          .content
          .hasValueNotifier
          .removeListener(initElementContainer);
      ElementContainer? container = element.tryGetContainer();
      if (container != null) {
        childKeys.clear();
        container.childNotifier.removeListener(_onChildrenChanged);
      }
    }
  }

  void _onChildrenChanged() {
    Map<String, GlobalKey> oldKeys = childKeys;
    childKeys.clear();
    assert((element as BranchElement).content.value != null,
        "Changed children without value");

    for (var e in (element as BranchElement).content.value!.children) {
      childKeys[e.id] = oldKeys[e.id] ?? GlobalKey();
    }

    setState(() {});
  }

  void updateOnChange() {
    if (element.size.width.runtimeType != _lastWidthType ||
        element.size.height.runtimeType != _lastHeightType) {
      _lastWidthType = element.size.width.runtimeType;
      _lastHeightType = element.size.height.runtimeType;
      widget.onBodyChanged(element, widget.index);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    //return ChangeListener<UIElement>(
    //source: element,
    // builder: () {

    ElementContainer? container = element.tryGetContainer();
    Widget? contentOverride =
        container != null ? _containerOverride(container) : null;

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
          width: element.size.constantWidth,
          height: element.size.constantHeight,
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
        width: element.size.width.renderValue,
        height: element.size.height.renderValue,
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
    double size = sqrt(min(element.size.width.renderValue ?? 400,
        element.size.height.renderValue ?? 400));
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
              if ((element.size.height.renderValue ?? 2) < 1 &&
                  localDelta.dy < 0) {
                debugPrint("Height too small");
                return;
              }

              element.size.addHeight(localDelta.dy.ceilToDouble());
            }

            if (alignment == Alignment.bottomCenter) {
              return;
            }

            if ((element.size.width.renderValue ?? 2) < 1 &&
                localDelta.dx < 0) {
              debugPrint("Width too small");
              return;
            }

            element.size.addWidth(localDelta.dx.roundToDouble());
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
