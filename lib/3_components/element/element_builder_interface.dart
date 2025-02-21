import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/layout/context_popup.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:jouhakka_forge/3_components/element/ui_element_component.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

part 'element_builder_interface_extension.dart';

class ElementBuilderInterface extends StatefulWidget {
  final void Function(UIElement element, int index) onBodyChanged;

  final UIElement? element;
  final ElementRoot? root;
  final int index;
  final bool showContainerEditor;

  /// - Null means that there will be no scaling box.
  /// - CenterRight means vertical scaling.
  /// - BottomCenter means horizontal scaling.
  /// - BottomRight keeps ratio when scaling.
  final Alignment? scaleAlignment;

  const ElementBuilderInterface({
    required GlobalKey globalKey,
    required this.element,
    this.root,
    this.index = 0,
    required this.showContainerEditor,
    required this.onBodyChanged,
    this.scaleAlignment,
  })  : assert(
            element != null || root != null, "Element or root must be given"),
        super(key: globalKey);

  @override
  State<ElementBuilderInterface> createState() {
    return _ElementBuilderInterfaceState();
  }
}

class _ElementBuilderInterfaceState extends State<ElementBuilderInterface> {
  UIElement get element => widget.element!;
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
    if (widget.element == null) {
      return Center(
          child: _addChildButton(
              min((element.width.value) ?? 144, element.height.value ?? 200) /
                  6));
    }

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
        canApplyInfinity: !widget.showContainerEditor &&
            element.parent != null &&
            element.parent!.type is SingleChildElementType,
        overrideContent: contentOverride,
        overridePadding: contentOverride != null &&
            element.padding.hasValue &&
            widget.showContainerEditor,
      );

      try {
        return SizedBox(
          width: element.width.tryGetFixed(),
          height: element.height.tryGetFixed(),
          child: ClickDetector(
            opaque: true,
            onPointerEvent: _onPointerEvent,
            primaryActionDown: (_) {
              Session.selectedElement.value = element;
            },
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.loose,
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

    //},
    //);
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
                          ..._elementInterface(!contentOverridden),
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

  List<Widget> _elementInterface(bool showPrimary) {
    if (!showPrimary) return [];
    bool isMedia = element is TextElement ||
        element is ImageElement ||
        element is IconElement;

    double buttonSize =
        sqrt(min(element.width.value ?? 20, element.height.value ?? 20))
                .toInt() *
            2;

    List<MyIconButton> buttons;
    if (isMedia) {
      buttons = [
        _wrapButton(buttonSize),
        _replaceButton(buttonSize),
        _stackButton(buttonSize),
      ];
    } else {
      buttons = [
        _addChildButton(buttonSize),
        _replaceButton(buttonSize),
        _stackButton(buttonSize),
      ];
    }

    return [
      Align(
        alignment: Alignment.center,
        child: _buttonContainer(buttons, buttonSize / 4, buttonSize / 4),
      )
    ];
  }

  Widget _buttonContainer(
      List<MyIconButton> buttons, double spacing, double padding) {
    assert(buttons.length <= 4 && buttons.isNotEmpty,
        "Button count must be between 1 and 4");

    return LayoutBuilder(builder: (context, constraints) {
      double aspectRatio = constraints.maxWidth / constraints.maxHeight;

      int crossAxisCount = 1;
      if ((buttons.length == 2 || buttons.length == 3) && aspectRatio > 1.0) {
        crossAxisCount = buttons.length;
      } else if (buttons.length == 4) {
        if (aspectRatio > 0.5) {
          if (aspectRatio > 2) {
            crossAxisCount = 4;
          } else {
            crossAxisCount = 2;
          }
        }
      }

      double maxWidth = crossAxisCount * buttons[0].size +
          padding * 2 +
          spacing * (crossAxisCount - 1);

      return Center(
        child: Container(
          color: Colors.white.withValues(alpha: 0.8),
          width: maxWidth,
          padding: EdgeInsets.all(padding),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: buttons,
          ),
        ),
      );
    });
  }

  MyIconButton _addChildButton(double size) {
    return MyIconButton(
      icon: Icons.add_circle_outline,
      tooltip: "Add child",
      size: size,
      primaryAction: (_) {
        onAddChild(
          UIElementType.box,
        );
      },
      secondaryAction: (details) {
        ContextPopup.open(
          context,
          clickPosition: details.globalPosition,
          child: ElementPicker(
            onElementSelected: (type) {
              onAddChild(type);
              ContextPopup.close();
            },
          ),
        );
      },
    );
  }

  MyIconButton _stackButton(double size) {
    return MyIconButton(
      icon: Icons.library_add,
      size: size,
      primaryAction: (details) {
        onStack();
      },
    );
  }

  MyIconButton _wrapButton(double size) {
    return MyIconButton(
      icon: Icons.crop_free,
      size: size,
      primaryAction: (details) {
        onWrap();
      },
    );
  }

  MyIconButton _replaceButton(double size) {
    return MyIconButton(
      icon: Icons.sync,
      size: size,
      primaryAction: (details) {
        ContextPopup.open(
          context,
          clickPosition: details.globalPosition,
          child: ElementPicker(onElementSelected: (element) {
            onReplace(element);
          }),
        );
      },
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
            if (alignment != Alignment.centerRight) {
              if ((element.height.value ?? 2) < 1 && details.delta.dy < 0) {
                debugPrint("Height too small");
                return;
              }

              element.height.add(details.delta.dy.ceilToDouble());
            }

            if (alignment == Alignment.bottomCenter) {
              return;
            }

            if ((element.width.value ?? 2) < 1 && details.delta.dx < 0) {
              debugPrint("Width too small");
              return;
            }

            element.width.add(details.delta.dx.ceilToDouble());
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

  void _onPointerEvent(PointerEvent event) {
    if (Session.hoverLocked) return;
    if (event is PointerEnterEvent ||
        (event is PointerHoverEvent && Session.hoveredElement.value == null)) {
      Session.hoveredElement.value = element;
    } else if (event is PointerExitEvent &&
        Session.hoveredElement.value == element) {
      Session.hoveredElement.value = null;
    }
  }

  void onWrap() {
    ContainerElement wrap = ContainerElement(
        children: [element],
        type: SingleChildElementType(),
        root: element.root,
        parent: element.parent);
    widget.onBodyChanged(wrap, widget.index);
  }

  void onStack() {
    ContainerElement stack = ContainerElement(
      children: [element],
      type: StackElementType(),
      root: element.root,
      parent: element.parent,
    );
    widget.onBodyChanged(stack, widget.index);
  }

  void onReplace(UIElementType type) {
    UIElement newElement = UIElement.fromType(
        type, widget.element?.root ?? widget.root!, widget.element?.parent);
    widget.onBodyChanged(newElement, widget.index);
  }

  void onAddChild(UIElementType type) {
    late ContainerElement singleChildElement;
    if (widget.element != null) {
      singleChildElement =
          ContainerElement.from(element, type: SingleChildElementType());
    } else {
      singleChildElement = ContainerElement(
        type: SingleChildElementType(),
        root: widget.root!,
        parent: null,
      );
    }
    singleChildElement.addChild(
        UIElement.fromType(type, singleChildElement.root, singleChildElement));
    childKeys.add(GlobalKey());
    widget.onBodyChanged(singleChildElement, widget.index);
  }
}
