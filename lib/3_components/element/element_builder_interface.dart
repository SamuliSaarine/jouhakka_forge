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
import 'package:web/web.dart' as web;

class ElementBuilderInterface extends StatefulWidget {
  final void Function(UIElement element)? onBodyChanged;

  final UIElement? element;
  final ElementRoot? root;
  final bool isHovering;
  final Function(bool hovering) onHoverChange;
  final int index;
  const ElementBuilderInterface({
    super.key,
    required this.element,
    this.root,
    this.index = 0,
    this.onBodyChanged,
    required this.onHoverChange,
    this.isHovering = false,
  }) : assert(element != null || root != null, "Element or root must be given");

  @override
  State<ElementBuilderInterface> createState() {
    return _ElementBuilderInterfaceState();
  }
}

//TODO: Adjust element size by dragging
class _ElementBuilderInterfaceState extends State<ElementBuilderInterface> {
  UIElement get element => widget.element!;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.element == null) return Center(child: _addChildButton());
    /*return ValueListener(
      source: Session.hoveredElement,
      builder: (hoveredElement) {
        bool isHovering = hoveredElement == widget.element;
        widget.onHoverChange(isHovering);*/
    Widget child = element is ContainerElement
        ? ContainerEditor(
            key: ValueKey("${element.hashCode}_c"),
            isHovering: widget.isHovering,
            element: element as ContainerElement,
            showBorder: true, //element.parent != null,)
          )
        : _elementInterface(widget.isHovering);
    return MouseRegion(
      onEnter: (_) {
        Session.hoveredElement.value = widget.element;
        widget.onHoverChange(true);
      },
      onExit: (_) {
        Session.hoveredElement.value = null;
        widget.onHoverChange(false);
      },
      onHover: (_) {
        Session.hoveredElement.value ??= widget.element;
        widget.onHoverChange(true);
      },
      hitTestBehavior: HitTestBehavior.opaque,
      child: child,
    );
    //},
    //);
  }

  Widget _elementInterface(bool isHovering) {
    if (!isHovering) return widget.element!.wireframe();
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
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.element!.wireframe(wrappedToInterface: true),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                onPanStart: (details) {
                  debugPrint("Changing cursor");
                  Session.globalCursor.value = SystemMouseCursors.resizeUpDown;
                },
                onPanUpdate: (details) {
                  //debugPrint("Pan update: ${details.delta}");
                  if (element.height.type != SizeType.fixed) {
                    element.height.type = SizeType.fixed;
                  }
                },
                onPanEnd: (details) {
                  debugPrint("Resetting cursor");
                  Session.globalCursor.value = MouseCursor.defer;
                },
                child: Container(
                  color: Colors.blue,
                  height: 50,
                  width: 50,
                ),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                onPanUpdate: (details) {
                  debugPrint("Pan update: ${details.delta}");
                },
                child: Container(
                  color: Colors.blue,
                  height: 50,
                  width: 50,
                ),
              ),
            )
          ],
        ),
        Center(
          child: _buttonContainer(buttons),
        )
      ],
    );
  }

  Widget _buttonContainer(List<MyIconButton> buttons) {
    // Container to wrap buttons correctly
    const double padding = 8.0;
    const double spacing = 8.0;

    if (buttons.isEmpty || buttons.length > 4) {
      throw Exception("Button count must be between 1 and 4");
    }

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
        /*showPopover(
            context: context,
            direction: PopoverDirection.top,
            bodyBuilder: (context) {
              return ElementPicker(
                root: widget.root ?? widget.element!.root,
                parent: widget.element?.parent,
                onElementSelected: (element) {
                  onAddChild(element);
                },
              );
            });*/
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

  void onWrap() {
    ContainerElement wrap = ContainerElement(
        children: [element],
        type: SingleChildElementType(),
        root: element.root,
        parent: element.parent);
    widget.onBodyChanged?.call(wrap);
  }

  void onStack() {
    ContainerElement stack = ContainerElement(
      children: [element],
      type: StackElementType(),
      root: element.root,
      parent: element.parent,
    );
    widget.onBodyChanged?.call(stack);
  }

  void onReplace(UIElement element) {
    widget.onBodyChanged?.call(element);
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
    widget.onBodyChanged?.call(singleChildElement);
  }
}
