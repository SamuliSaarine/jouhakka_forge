part of 'element_builder_interface.dart';

extension _ElementBuilderInterfaceExtension on _ElementBuilderInterfaceState {
  Widget _containerOverride(ContainerElement containerElement) {
    void onAddChild(AddDirection direction, {TapUpDetails? details}) async {
      UIElement? pickedElement;
      if (details != null) {
        ContextPopup.open(
          context,
          clickPosition: details.globalPosition,
          child: ElementPicker(
            onElementSelected: (type) {
              pickedElement = UIElement.fromType(
                  type, containerElement.root, containerElement);
              ContextPopup.close();
            },
          ),
        );

        await ContextPopup.waitOnClose();

        if (pickedElement == null) return;
      }

      if (containerElement.type is SingleChildElementType) {
        containerElement.changeContainerType(FlexElementType(direction.axis));
      }
      childKeys.add(GlobalKey());
      containerElement.addChild(
        pickedElement ??
            (containerElement.children.isEmpty
                ? UIElement.defaultBox(containerElement.root,
                    parent: containerElement)
                : containerElement.children.last.clone()),
      );
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

    Widget childBuilder(UIElement child, int index) {
      void onBodyChanged(UIElement element, int index) {
        UIElement childElement = containerElement.children[index];
        if (childElement != element) {
          containerElement.replaceAt(index, element);
        }
        setState(() {});
      }

      try {
        if (childKeys.length <= index) {
          childKeys.add(GlobalKey());
          debugPrint("Key was not initialized properly");
        }

        Widget interface = ElementBuilderInterface(
          globalKey: childKeys[index], // ValueKey("${child.hashCode}_i"),
          element: child,
          root: containerElement.root,
          index: index,
          scaleAlignment: childScaleAlignment,
          showContainerEditor: widget.showContainerEditor,
          onBodyChanged: onBodyChanged,
        );

        bool isFlex = containerElement.type is FlexElementType;
        Axis direction = isFlex
            ? (containerElement.type as FlexElementType).direction
            : Axis.vertical;
        if (child.expands(axis: direction) && isFlex) {
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
      return ContainerChildEditor.from(
        containerElement,
        buttonSize: sqrt(min(
          element.width.value ?? 20,
          element.height.value ?? 20,
        )),
        show: widget.showContainerEditor,
        onAddChild: onAddChild,
        builder: childBuilder,
      );
    } catch (e, s) {
      debugPrint("Container override build failed: $e\n$s");
      rethrow;
    }
  }
}
