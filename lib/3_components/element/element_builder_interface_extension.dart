part of 'element_builder_interface.dart';

extension _ElementBuilderInterfaceExtension on _ElementBuilderInterfaceState {
  void _primaryAction(TapUpDetails details) {
    if (HardwareKeyboard.instance.isShiftPressed && element is BranchElement) {
      AddDirection? direction = _calculateDirection(details.localPosition);
      //debugPrint("Direction: $direction");
      (element as BranchElement).addElement(
        null,
        direction,
      );
    } else if (Session.selectedElement.value == element) {
      //debugPrint("Direction: ${_calculateDirection(details.localPosition)}");
    } else {
      Session.selectedElement.value = element;
    }
  }

  void _secondaryAction(TapDownDetails details) async {
    if (HardwareKeyboard.instance.isShiftPressed && element is BranchElement) {
      AddDirection? direction = _calculateDirection(details.localPosition);
      UIElementType? type = await _pickChild(details.globalPosition);
      if (type != null) {
        (element as BranchElement).addElement(type, direction);
      }
    } else {
      ContextMenu.open(
        context,
        details.globalPosition,
        [
          //New element
          if (element is BranchElement)
            ContextMenuItem("New element", action: (_) {
              AddDirection? direction =
                  _calculateDirection(details.localPosition);
              (element as BranchElement).addElement(null, direction);
            }),
          //Pick element
          if (element is BranchElement)
            ContextMenuItem("Pick element", action: (details) async {
              AddDirection? direction =
                  _calculateDirection(details.localPosition);
              UIElementType? type = await _pickChild(details.globalPosition);
              if (type != null) {
                (element as BranchElement).addElement(type, direction);
              }
            }),
          //Wrap element
          ContextMenuItem("Wrap with empty", action: (details) {
            onWrap(false);
          }),
          ContextMenuItem("Wrap with box", action: (details) {
            onWrap(true);
          }),
          //Replace element
          ContextMenuItem("Replace element", action: (details) async {
            UIElementType? type = await _pickChild(details.globalPosition);
            if (type != null) {
              onReplace(type);
            }
          }),
          //Delete
          ContextMenuItem("Delete", action: (details) {
            if (element.parent == null) {
              debugPrint("Cannot delete element without parent");
              return;
            }
            element.parent!.removeChild(element);
          }),

          //TODO: Copy and paste
        ],
      );
    }
  }

  Future<UIElementType?> _pickChild(Offset pickerPos) async {
    UIElementType? pickedElement;

    ContextPopup.open(
      context,
      clickPosition: pickerPos,
      child: ElementPicker(
        onElementSelected: (type) {
          pickedElement = type;
          ContextPopup.close();
        },
      ),
    );

    await ContextPopup.waitOnClose();

    if (pickedElement == null) return null;

    return pickedElement;
  }

  void _onPointerEvent(PointerEvent event) {
    void updateDirection({addHandler = false}) {
      bool lateHandler(KeyEvent keyEvent) {
        bool value = false;

        if (keyEvent is KeyDownEvent &&
            keyEvent.logicalKey == LogicalKeyboardKey.shiftLeft) {
          if (Session.hoveredElement.value == element &&
              Session.localHoverPosition != null) {
            Session.addDirection.value =
                _calculateDirection(Session.localHoverPosition!);
            value = true;
          }
          HardwareKeyboard.instance.removeHandler(lateHandler);
        }

        return value;
      }

      if (HardwareKeyboard.instance
          .isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft)) {
        Session.addDirection.value = _calculateDirection(event.localPosition);
      } else if (addHandler) {
        HardwareKeyboard.instance.addHandler(lateHandler);
      }
      Session.localHoverPosition = event.localPosition;
    }

    if (Session.hoverLocked) return;
    if (event is PointerHoverEvent && Session.hoveredElement.value == element) {
      updateDirection();
    }
    if (event is PointerEnterEvent ||
        (event is PointerHoverEvent && Session.hoveredElement.value == null)) {
      Session.hoveredElement.value = element;
      updateDirection(addHandler: true);
    } else if (event is PointerExitEvent &&
        Session.hoveredElement.value == element) {
      Session.hoveredElement.value = null;
      if (Session.addDirection.value != null) {
        Session.addDirection.value = null;
      }
    }
  }

  void onWrap(bool decorate) {
    BranchElement wrap = BranchElement(
      root: element.root,
      parent: element.parent,
      decoration: decorate ? ElementDecoration.defaultBox : null,
    );
    widget.onBodyChanged(wrap, widget.index);
  }

  // TOD: onStack

  void onReplace(UIElementType type) {
    UIElement newElement =
        UIElement.fromType(type, widget.element.root, widget.element.parent);
    widget.onBodyChanged(newElement, widget.index);
  }

  AddDirection? _calculateDirection(Offset localPos) {
    ElementContainer? container = element.tryGetContainer();
    if (container == null) {
      return null;
    }
    double extra = 0;
    double width = element.size.width.renderValue!;
    double height = element.size.height.renderValue!;
    if (Session.extraPadding.value) {
      extra = sqrt(min(width, height));
    }

    // Get child size and alignment

    Alignment alignment = container.type is SingleChildElementType
        ? (container.type as SingleChildElementType).alignment
        : Alignment.center;
    double childWidth = container.children.first.size.width.renderValue ??
        element.size.width.renderValue!;
    double childHeight = container.children.first.size.height.renderValue ??
        element.size.height.renderValue!;

    // Get padding
    EdgeInsets padding = container.padding.padding;
    double top = max(padding.top, extra);
    double bottom = max(padding.bottom, extra);
    double left = max(padding.left, extra);
    double right = max(padding.right, extra);

    // Adjust parent dimensions to account for padding
    double paddedWidth = width - left - right;
    double paddedHeight = height - top - bottom;

    // Calculate child's top-left position within the padded parent
    double childLeft =
        left + (paddedWidth - childWidth) * (alignment.x + 1) / 2;
    double childTop =
        top + (paddedHeight - childHeight) * (alignment.y + 1) / 2;
    double childRight = childLeft + childWidth;
    double childBottom = childTop + childHeight;

    // Midpoints for diagonal calculations
    double midX = (childLeft + childRight) / 2;
    double midY = (childTop + childBottom) / 2;

    // Slopes for diagonal boundaries
    double slopeTopLeft = (midY - top) / (midX - left);
    double slopeTopRight = (midY - top) / (width - right - midX);
    double slopeBottomLeft = (height - bottom - midY) / (midX - left);
    double slopeBottomRight = (height - bottom - midY) / (width - right - midX);

    // Compute diagonal boundaries
    double boundaryTopLeft = slopeTopLeft * (localPos.dx - left) + top;
    double boundaryTopRight =
        slopeTopRight * (width - right - localPos.dx) + top;
    double boundaryBottomLeft =
        height - bottom - slopeBottomLeft * (localPos.dx - left);
    double boundaryBottomRight =
        height - bottom - slopeBottomRight * (width - right - localPos.dx);

    //debugPrint("Pos: $localPos. Boundaries: $boundaryTopLeft, $boundaryTopRight, $boundaryBottomLeft, $boundaryBottomRight");

    // Determine correct direction
    if (localPos.dy < boundaryTopLeft && localPos.dy < boundaryTopRight) {
      //debugPrint("Slope to top");
      return AddDirection.top;
    } else if (localPos.dy > boundaryBottomLeft &&
        localPos.dy > boundaryBottomRight) {
      //debugPrint("Slope to bottom");
      return AddDirection.bottom;
    } else if (localPos.dx < midX) {
      //debugPrint("Slope to left");
      return AddDirection.left;
    } else {
      //debugPrint("Slope to right");
      return AddDirection.right;
    }
  }

  Widget _containerOverride(ElementContainer containerElement) {
    Widget childBuilder(UIElement child, int index) {
      void onBodyChanged(UIElement element, int index) {
        UIElement childElement = containerElement.children[index];
        if (childElement != element) {
          containerElement.replaceAt(index, element);
        }
        setState(() {});
      }

      Alignment solveScaleAlignment() {
        try {
          Alignment childScaleAlignment = Alignment.bottomRight;
          if (containerElement.type is FlexElementType) {
            FlexElementType flexType = containerElement.type as FlexElementType;
            if (flexType.direction == Axis.horizontal) {
              childScaleAlignment = Alignment.centerRight;
            } else {
              childScaleAlignment = Alignment.bottomCenter;
            }
          }
          return childScaleAlignment;
        } catch (e) {
          debugPrint("Failed to solve scale alignment: $e");
          return Alignment.bottomRight;
        }
      }

      Alignment childScaleAlignment = solveScaleAlignment();

      try {
        assert(childKeys.containsKey(child.id),
            "Child keys are not updated properly");

        Axis? flexDirection = containerElement.type is FlexElementType
            ? (containerElement.type as FlexElementType).direction
            : null;

        bool expandChild =
            flexDirection != null && child.size.expands(axis: flexDirection);

        Widget interface = ElementBuilderInterface(
          globalKey: childKeys[child.id]!, // ValueKey("${child.hashCode}_i"),
          element: child,
          index: index,
          scaleAlignment: childScaleAlignment,
          onBodyChanged: onBodyChanged,
          expandStack: expandChild,
        );

        if (expandChild) {
          //TODO: Implement flex
          return Expanded(
            child: interface,
          );
        } else {
          return interface;
        }
      } catch (e, s) {
        debugPrint("Container override builder failed: $e\n$s");
        rethrow;
      }
    }

    try {
      return containerElement.type.getWidget(
        [
          for (int i = 0; i < containerElement.children.length; i++)
            childBuilder(containerElement.children[i], i)
        ],
      );
    } catch (e, s) {
      debugPrint("Container override build failed: $e\n$s");
      rethrow;
    }
  }
}
