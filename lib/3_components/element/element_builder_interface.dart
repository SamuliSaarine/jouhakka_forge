import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/layout/context_menu.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:jouhakka_forge/3_components/element/ui_element_component.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/0_models/container_element.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

class ElementBuilderInterface extends StatefulWidget {
  final void Function(UIElement element, int index)? onBodyChanged;

  final UIElement? element;
  final ElementRoot? root;
  final Function(Size? size, bool hover) onResizeRequest;
  final int index;
  const ElementBuilderInterface({
    super.key,
    required this.element,
    this.root,
    this.index = 0,
    this.onBodyChanged,
    required this.onResizeRequest,
  }) : assert(element != null || root != null, "Element or root must be given");

  @override
  State<ElementBuilderInterface> createState() {
    return _ElementBuilderInterfaceState();
  }
}

//TODO: Adjust element size by dragging
class _ElementBuilderInterfaceState extends State<ElementBuilderInterface> {
  UIElement get element => widget.element!;
  Size? requiredByContainerEditor;
  bool directChildHovering = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.element == null) return Center(child: _addChildButton());

    bool isHovering =
        Session.hoveredElement.value == widget.element || directChildHovering;

    Widget? contentOverride;
    if (element is ContainerElement) {
      ContainerElement containerElement = element as ContainerElement;
      Widget expandChild(Widget child) {
        if (element.expands()) {
          if (containerElement.type is FlexElementType || isHovering) {
            return Expanded(
              child: child,
            );
          } else if (containerElement.type is StackElementType) {
            return Positioned.fill(
              child: child,
            );
          }
        }
        return child;
      }

      contentOverride = ContainerChildEditor.from(
        containerElement,
        isHovering: isHovering,
        onAddChild: (direction) {
          if (containerElement.type is SingleChildElementType) {
            containerElement
                .changeContainerType(FlexElementType(direction.axis));
          }
          containerElement.addChild(
            UIElement.defaultBox(containerElement.root,
                parent: containerElement),
          );
          setState(() {});
        },
        onButtonSizeUpdate: (newSize) {
          requiredByContainerEditor = newSize;
        },
        children: [
          for (int i = 0; i < containerElement.children.length; i++)
            expandChild(
              ElementBuilderInterface(
                key: ValueKey("${containerElement.children[i].hashCode}_i"),
                element: containerElement.children[i],
                root: containerElement.root,
                index: i,
                onBodyChanged: (element, index) {
                  containerElement.children[index] = element;
                  setState(() {});
                },
                onResizeRequest: (size, hover) {
                  assert(size != null || hover,
                      "Size must be given if hovering is false");
                  if (requiredByContainerEditor != null && hover) {
                    if (size != null) {
                      size = Size(size.width + requiredByContainerEditor!.width,
                          size.height + requiredByContainerEditor!.height);
                    } else {
                      size = requiredByContainerEditor;
                    }
                  }

                  directChildHovering = hover;

                  widget.onResizeRequest(size, hover);
                  /*if (size != null) {
                    widget.onResizeRequest(size, false);
                  } else {
                    setState(() {});
                  }*/
                },
              ),
            ),
        ],
      );
    }

    Widget current = ElementWidget(
      element: element,
      globalKey: GlobalKey(),
      wireframe: true,
      overrideContent: contentOverride,
    );

    return SizedBox(
      width: element.width.tryGetFixed(),
      height: element.height.tryGetFixed(),
      child: MouseRegion(
        onEnter: (_) {
          if (Session.hoveredElement.value == widget.element) return;
          Session.hoveredElement.value = widget.element;
          debugPrint("Hovering ${widget.key}");
          widget.onResizeRequest(requiredByContainerEditor, true);
        },
        onExit: (_) {
          if (Session.hoveredElement.value == widget.element) {
            Session.hoveredElement.value = null;
            widget.onResizeRequest(Size.zero, false);
          }
        },
        onHover: (_) {
          if (Session.hoveredElement.value == null) {
            Session.hoveredElement.value = widget.element;
            widget.onResizeRequest(requiredByContainerEditor, true);
          }
        },
        hitTestBehavior: HitTestBehavior.opaque,
        opaque: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            current,
            ..._elementInterface(isHovering, contentOverride == null),
            if (isHovering)
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListener(
                    source: Session.hoveredElement,
                    builder: (value) {
                      if (value == widget.element) {
                        debugPrint("Drawing border ${widget.key}");
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            if (isHovering)
              Align(
                alignment: Alignment.bottomRight,
                child: _scaleBox(),
              )
          ],
        ),
      ),
    );
  }

  List<Widget> _elementInterface(bool isHovering, bool showPrimary) {
    if (!showPrimary) return [];
    if (!isHovering) return [];
    bool isMedia = element is TextElement || element is ImageElement;
    List<MyIconButton> buttons;
    if (isMedia) {
      buttons = [
        _wrapButton(),
        _replaceButton(),
        _stackButton(),
      ];
    } else {
      buttons = [
        _addChildButton(),
        _replaceButton(),
        _stackButton(),
      ];
    }
    return [
      Align(
        alignment: Alignment.center,
        child: _buttonContainer(buttons),
      )
    ];
  }

  Widget _buttonContainer(List<MyIconButton> buttons) {
    // Container to wrap buttons correctly
    const double padding = 8.0;
    const double spacing = 8.0;

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
          padding: const EdgeInsets.all(padding),
          child: Wrap(
            spacing: spacing,
            children: buttons,
          ),
        ),
      );
    });
  }

  MyIconButton _addChildButton() {
    return MyIconButton(
      icon: Icons.add_circle_outline,
      tooltip: "Add child",
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

  MyIconButton _stackButton() {
    return MyIconButton(
      icon: Icons.library_add,
      primaryAction: (details) {
        onStack();
      },
    );
  }

  MyIconButton _wrapButton() {
    return MyIconButton(
      icon: Icons.crop_free,
      primaryAction: (details) {
        onWrap();
      },
    );
  }

  MyIconButton _replaceButton() {
    return MyIconButton(
      icon: Icons.sync,
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
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      child: GestureDetector(
        onPanStart: (details) {
          debugPrint("Changing cursor");
          Session.globalCursor.value = SystemMouseCursors.resizeUpDown;
        },
        onPanUpdate: (details) {
          if (element.height.type != SizeType.fixed) {
            element.height.type = SizeType.fixed;
          }
          if (element.width.type != SizeType.fixed) {
            element.width.type = SizeType.fixed;
          }
          element.height.value =
              (element.height.value ?? 12) + details.delta.dy;
          element.width.value = (element.width.value ?? 12) + details.delta.dx;
          setState(() {});
        },
        onPanEnd: (details) {
          debugPrint("Resetting cursor");
          Session.globalCursor.value = MouseCursor.defer;
        },
        child: Container(
          color: Colors.blue,
          height: 20,
          width: 20,
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
    widget.onBodyChanged?.call(singleChildElement, widget.index);
  }
}
