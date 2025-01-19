import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/1_helpers/functions.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/layout/context_menu.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:jouhakka_forge/3_components/element/ui_element_component.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/0_models/container_element.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

class ElementBuilderInterface extends StatefulWidget {
  final void Function(UIElement element, int index)? onBodyChanged;

  /// Returns true if state was set in parent
  final bool Function(bool isHovering)? onHover;

  final UIElement? element;
  final ElementRoot? root;
  final int index;

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
    this.onBodyChanged,
    this.onHover,
    this.scaleAlignment,
  })  : assert(
            element != null || root != null, "Element or root must be given"),
        super(key: globalKey);

  @override
  State<ElementBuilderInterface> createState() {
    return _ElementBuilderInterfaceState();
  }
}

//TODO: Jos columnin sisällä olevan columnin sisällä yrität resizata, niin ei toimi.
class _ElementBuilderInterfaceState extends State<ElementBuilderInterface> {
  UIElement get element => widget.element!;
  bool childIsHovering = false;
  GlobalKey globalKey = GlobalKey();
  List<GlobalKey> childKeys = [];
  double buttonSize = 20;
  bool _isSelected = false;

  @override
  void initState() {
    globalKey = GlobalKey();
    if (element is ContainerElement) {
      ContainerElement containerElement = element as ContainerElement;
      for (int i = 0; i < containerElement.children.length; i++) {
        childKeys.add(GlobalKey());
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.element == null) {
      return Center(
          child: _addChildButton(
              min((element.width.value) ?? 144, element.height.value ?? 200) /
                  6));
    }

    return ValueListener(
        source: Session.selectedElement,
        condition: (value) {
          return _isSelected || value == widget.element;
        },
        builder: (selectedElement) {
          _isSelected = selectedElement == widget.element;
          bool iAmHovering = Session.hoveredElement.value == widget.element;
          bool isHovering = iAmHovering || childIsHovering;

          Widget? contentOverride;
          if (element is ContainerElement) {
            ContainerElement containerElement = element as ContainerElement;

            Alignment childScaleAlignment = Alignment.bottomRight;
            if (containerElement.type is FlexElementType) {
              FlexElementType flexType =
                  containerElement.type as FlexElementType;
              if (flexType.direction == Axis.horizontal) {
                childScaleAlignment = Alignment.centerRight;
              } else {
                childScaleAlignment = Alignment.bottomCenter;
              }
            }

            contentOverride = ContainerChildEditor.from(
              containerElement,
              isHovering: isHovering,
              onAddChild: (direction) {
                debugPrint(
                    "${(widget.element as ContainerElement).children.length}");
                if (containerElement.type is SingleChildElementType) {
                  containerElement
                      .changeContainerType(FlexElementType(direction.axis));
                }
                containerElement.addChild(
                  UIElement.defaultBox(containerElement.root,
                      parent: containerElement),
                );

                debugPrint(
                    "${(widget.element as ContainerElement).children.length}");
                setState(() {
                  childKeys.add(GlobalKey());
                });
              },
              builder: (child, index) {
                Widget interface = ElementBuilderInterface(
                  globalKey:
                      childKeys[index], // ValueKey("${child.hashCode}_i"),
                  element: child,
                  root: containerElement.root,
                  index: index,
                  scaleAlignment: childScaleAlignment,
                  onBodyChanged: (element, index) {
                    if (containerElement.children[index] != element) {
                      containerElement.children[index] = element;
                    }

                    setState(() {});
                  },
                  onHover: (isHovering) {
                    if (isHovering == childIsHovering) return false;
                    childIsHovering = isHovering;
                    if (widget.onHover != null) {
                      bool parentSetState = widget.onHover!(false);
                      if (parentSetState) {
                        return true;
                      }
                    }
                    setState(() {});
                    return true;
                  },
                );

                bool isFlex = containerElement.type is FlexElementType;
                Axis direction = isFlex
                    ? (containerElement.type as FlexElementType).direction
                    : Axis.vertical;
                if (child.expands(axis: direction) && (isFlex || isHovering)) {
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
          );

          /*if (element.expands()) {
      current = Positioned.fill(
        child: current,
      );
    }*/

          return SizedBox(
            width: element.width.tryGetFixed(),
            height: element.height.tryGetFixed(),
            child: MouseRegion(
              onEnter: (_) {
                if (Session.hoverLocked) return;
                if (Session.hoveredElement.value == widget.element) return;
                Session.hoveredElement.value = widget.element;
                if (widget.onHover != null) {
                  widget.onHover!(true);
                } else {
                  setState(() {});
                }
              },
              onExit: (_) {
                if (Session.hoverLocked) return;
                if (Session.hoveredElement.value == widget.element) {
                  Session.hoveredElement.value = null;
                  if (widget.onHover != null) {
                    widget.onHover!(false);
                  } else {
                    setState(() {});
                  }
                }
              },
              onHover: (_) {
                if (Session.hoverLocked) return;
                if (Session.hoveredElement.value != null) return;
                debugPrint("Hover ${widget.key}");
                Session.hoveredElement.value = widget.element;
                if (widget.onHover != null) {
                  widget.onHover!(true);
                } else {
                  setState(() {});
                }
              },
              hitTestBehavior: HitTestBehavior.opaque,
              child: GestureDetector(
                onTap: () {
                  Session.selectedElement.value = widget.element;
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    current,
                    if (iAmHovering || _isSelected) ...[
                      ..._elementInterface(contentOverride == null),
                      Positioned.fill(
                        child: IgnorePointer(
                            child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                        )),
                      ),
                      if (widget.scaleAlignment != null) _scaleBox(),
                    ]
                  ],
                ),
              ),
            ),
          );
        });
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
        ContextMenu.open(
          context,
          clickPosition: details.globalPosition,
          child: ElementPicker(
              root: widget.root ?? widget.element!.root,
              parent: widget.element?.parent,
              onElementSelected: (element) {
                onAddChild(element);
                ContextMenu.close();
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
        ContextMenu.open(
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
            bool updateParent = false;
            if (alignment != Alignment.centerRight) {
              //Vertical resize
              if (element.height.type != SizeType.fixed) {
                element.height.type = SizeType.fixed;
                updateParent = true;
              }

              if ((element.height.value ?? 2) < 1 && details.delta.dy < 0) {
                debugPrint("Height too small");
                return;
              }

              element.height.value =
                  ((element.height.value ?? 12) + details.delta.dy)
                      .ceilToDouble();
            }

            if (alignment == Alignment.bottomCenter) {
              if (updateParent && widget.onBodyChanged != null) {
                widget.onBodyChanged?.call(element, widget.index);
              } else {
                setState(() {});
              }
              return;
            }

            //Horizontal resize
            if (element.width.type != SizeType.fixed) {
              element.width.type = SizeType.fixed;
              widget.onBodyChanged?.call(element, widget.index);
            }

            if ((element.width.value ?? 2) < 1 && details.delta.dx < 0) {
              debugPrint("Width too small");
              return;
            }

            element.width.value =
                ((element.width.value ?? 12) + details.delta.dx).ceilToDouble();

            if (updateParent && widget.onBodyChanged != null) {
              widget.onBodyChanged?.call(element, widget.index);
            } else {
              setState(() {});
            }
          },
          onPanEnd: (details) {
            debugPrint("Resetting cursor");

            Session.hoveredElement.value = null;
            widget.onHover?.call(false);
            Session.hoverLocked = false;
            Session.globalCursor.value = MouseCursor.defer;
          },
          onPanCancel: () {
            debugPrint("Pan cancelled");

            Session.hoveredElement.value = null;
            widget.onHover?.call(false);
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
    widget.onBodyChanged?.call(wrap, widget.index);
  }

  void onStack() {
    ContainerElement stack = ContainerElement(
      children: [element],
      type: StackElementType(),
      root: element.root,
      parent: element.parent,
    );
    widget.onBodyChanged?.call(stack, widget.index);
  }

  void onReplace(UIElement element) {
    widget.onBodyChanged?.call(element, widget.index);
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
    widget.onBodyChanged?.call(singleChildElement, widget.index);
  }
}
