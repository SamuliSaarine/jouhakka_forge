import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/1_helpers/functions.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/layout/context_popup.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:jouhakka_forge/3_components/element/ui_element_component.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/0_models/container_element.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

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
  late final GlobalKey globalKey;
  final List<GlobalKey> childKeys = [];
  double buttonSize = 20;
  bool _isSelected = false;
  bool _isHovering = false;
  late SizeType _lastWidthType;
  late SizeType _lastHeightType;

  @override
  void initState() {
    globalKey = GlobalKey();
    if (element is ContainerElement) {
      ContainerElement containerElement = element as ContainerElement;
      for (int i = 0; i < containerElement.children.length; i++) {
        childKeys.add(GlobalKey());
      }
    }

    _lastWidthType = element.width.type;
    _lastHeightType = element.height.type;
    element.addListener(updateOnChange);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ElementBuilderInterface oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the source has changed, reattach the listener to the new source
    if (widget.onBodyChanged != oldWidget.onBodyChanged) {
      element.removeListener(updateOnChange);
      element.addListener(updateOnChange);
    }
  }

  @override
  void dispose() {
    element.removeListener(updateOnChange);
    super.dispose();
  }

  void updateOnChange() {
    if (element.width.type != _lastWidthType ||
        element.height.type != _lastHeightType) {
      _lastWidthType = element.width.type;
      _lastHeightType = element.height.type;
      widget.onBodyChanged(element, widget.index);
    } else {
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
    Widget? contentOverride;
    if (element is ContainerElement) {
      ContainerElement containerElement = element as ContainerElement;

      Alignment childScaleAlignment = Alignment.bottomRight;
      if (containerElement.type is FlexElementType) {
        FlexElementType flexType = containerElement.type as FlexElementType;
        if (flexType.direction == Axis.horizontal) {
          childScaleAlignment = Alignment.centerRight;
        } else {
          childScaleAlignment = Alignment.bottomCenter;
        }
      }

      contentOverride = ContainerChildEditor.from(
        containerElement,
        isHovering: widget.showContainerEditor,
        onAddChild: (direction) {
          debugPrint("${(widget.element as ContainerElement).children.length}");
          if (containerElement.type is SingleChildElementType) {
            containerElement
                .changeContainerType(FlexElementType(direction.axis));
          }
          containerElement.addChild(
            UIElement.defaultBox(containerElement.root,
                parent: containerElement),
          );

          debugPrint("${(widget.element as ContainerElement).children.length}");
          setState(() {
            childKeys.add(GlobalKey());
          });
        },
        builder: (child, index) {
          Widget interface = ElementBuilderInterface(
            globalKey: childKeys[index], // ValueKey("${child.hashCode}_i"),
            element: child,
            root: containerElement.root,
            index: index,
            scaleAlignment: childScaleAlignment,
            showContainerEditor: widget.showContainerEditor,
            onBodyChanged: (element, index) {
              if (containerElement.children[index] != element) {
                containerElement.children[index] = element;
              }

              setState(() {});
            },
          );

          bool isFlex = containerElement.type is FlexElementType;
          Axis direction = isFlex
              ? (containerElement.type as FlexElementType).direction
              : Axis.vertical;
          if (child.expands(axis: direction) &&
              (isFlex || widget.showContainerEditor)) {
            return Expanded(
              child: interface,
            );
          } else {
            return interface;
          }
        },
      );
    }

    Widget current = ElementWidget(
      element: element,
      globalKey: globalKey,
      wireframe: true,
      overrideContent: contentOverride,
      overridePadding: contentOverride != null &&
          element.padding.hasValue &&
          widget.showContainerEditor,
    );

    return SizedBox(
      width: element.width.tryGetFixed(),
      height: element.height.tryGetFixed(),
      child: MouseRegion(
        onEnter: (details) async {
          if (Session.hoverLocked) return;
          Session.hoveredElement.value = widget.element;
        },
        onExit: (_) {
          if (Session.hoverLocked) return;
          if (Session.hoveredElement.value == widget.element) {
            Session.hoveredElement.value = null;
          }
        },
        onHover: (_) {
          if (Session.hoverLocked) return;
          if (Session.hoveredElement.value != null) return;
          Session.hoveredElement.value = widget.element;
        },
        hitTestBehavior: HitTestBehavior.opaque,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Session.selectedElement.value = widget.element;
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              current,
              ValueListener(
                source: Session.hoveredElement,
                condition: (value) {
                  return _isHovering != (value == widget.element);
                },
                builder: (hoveringElement) {
                  _isHovering = hoveringElement == widget.element;
                  return ValueListener(
                    source: Session.selectedElement,
                    condition: (value) {
                      return _isSelected != (value == widget.element);
                    },
                    builder: (selectedElement) {
                      _isSelected = selectedElement == widget.element;
                      bool showEditor = _isSelected || _isHovering;
                      return Stack(
                        children: showEditor
                            ? [
                                ..._elementInterface(contentOverride == null),
                                Positioned.fill(
                                  child: IgnorePointer(
                                      child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.green, width: 1),
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
            ],
          ),
        ),
      ),
    );
    //},
    //);
  }

  List<Widget> _elementInterface(bool showPrimary) {
    if (!showPrimary) return [];
    bool isMedia = element is TextElement || element is ImageElement;

    return [
      LayoutBuilder(builder: (context, constraints) {
        double buttonSize =
            fastSqrt(min(constraints.maxWidth, constraints.maxHeight)).toInt() *
                2;

        this.buttonSize = buttonSize;

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

        return Align(
          alignment: Alignment.center,
          child: _buttonContainer(buttons, buttonSize / 4, buttonSize / 4),
        );
      })
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
          color: Colors.white.withOpacity(0.8),
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
      primaryAction: (details) {
        ContextPopup.open(
          context,
          clickPosition: details.globalPosition,
          child: ElementPicker(
              root: widget.root ?? widget.element!.root,
              parent: widget.element?.parent,
              onElementSelected: (element) {
                onAddChild(element);
                ContextPopup.close();
              }),
        );
      },
      secondaryAction: (_) {
        onAddChild(
          UIElement.defaultBox(widget.root ?? element.root,
              parent: widget.element),
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
          child: ElementPicker(
              root: widget.root ?? widget.element!.root,
              parent: widget.element?.parent,
              onElementSelected: (element) {
                onReplace(element);
              }),
        );
      },
    );
  }

  Widget _scaleBox() {
    Alignment alignment = widget.scaleAlignment!;
    double size = fastSqrt(min(widget.element!.width.value ?? 400,
        widget.element!.height.value ?? 400));
    return Align(
      alignment: alignment,
      child: MouseRegion(
        cursor: alignment.getScaleCursor(),
        child: GestureDetector(
          onPanStart: (details) {
            if (!_isSelected) {
              Session.selectedElement.value = widget.element;
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
            height: size,
            width: size,
          ),
        ),
      ),
    );
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

  void onReplace(UIElement element) {
    widget.onBodyChanged(element, widget.index);
  }

  void onAddChild(UIElement element) {
    late ContainerElement singleChildElement;
    if (widget.element != null) {
      singleChildElement = ContainerElement.from(widget.element!,
          type: SingleChildElementType(), children: [element]);
    } else {
      singleChildElement = ContainerElement(
        children: [element],
        type: SingleChildElementType(),
        root: widget.root ?? this.element.root,
        parent: widget.element?.parent,
      );
    }
    childKeys.add(GlobalKey());
    widget.onBodyChanged(singleChildElement, widget.index);
  }
}
