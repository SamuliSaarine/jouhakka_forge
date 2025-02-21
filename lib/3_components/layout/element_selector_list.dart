import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

class ElementSelectorList extends StatefulWidget {
  final ContainerElement? parentElement;
  final ElementRoot root;
  final void Function(UIElement item) onSelection;

  const ElementSelectorList(
    this.parentElement, {
    super.key,
    required this.onSelection,
    required this.root,
  });

  @override
  State<ElementSelectorList> createState() => _ElementSelectorListState();
}

class _ElementSelectorListState extends State<ElementSelectorList> {
  int length = 1;
  Set<int> expandedContainers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeListener(
        source: widget.parentElement?.childNotifier ?? widget.root,
        builder: () {
          length = widget.parentElement?.children.length ?? 1;
          debugPrint("Updating ElementSelectorList");
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int index = 0; index < length; index++)
                _resolveWidget(index),
            ],
          );
        });
  }

  Widget _resolveWidget(int index) {
    UIElement? item = widget.parentElement?.children[index] ?? widget.root.body;
    if (item is ContainerElement) {
      return _containerListWidget(item, index);
    } else {
      return _itemWidget(item, index);
    }
  }

  Widget _containerListWidget(ContainerElement containerElement, int index) {
    if (expandedContainers.contains(index) &&
        containerElement.children.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _containerElementWidget(containerElement, index),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: ElementSelectorList(
              containerElement,
              onSelection: (item) => widget.onSelection(item),
              root: widget.root,
            ),
          ),
        ],
      );
    } else {
      return _containerElementWidget(containerElement, index);
    }
  }

  Widget _containerElementWidget(ContainerElement element, int index) {
    bool isExpanded = expandedContainers.contains(index);
    void expandAction(_) {
      setState(() {
        isExpanded
            ? expandedContainers.remove(index)
            : expandedContainers.add(index);
      });
    }

    return Row(
      children: [
        ClickDetector(
          primaryActionDown: expandAction,
          builder: (hovering, _) => ColoredBox(
            color: hovering ? MyColors.mediumDifference : Colors.transparent,
            child: Icon(isExpanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right),
          ),
        ),
        Expanded(child: _itemWidget(element, index)),
      ],
    );
  }

  Widget _itemWidget(UIElement item, int index) {
    return ClickDetector(
      primaryActionDown: (_) {
        widget.onSelection(item);
      },
      builder: (hovering, _) => ColoredBox(
        color: (hovering || item == Session.selectedElement)
            ? MyColors.mediumDifference
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(
              left: 2.0, right: 8.0, top: 2.0, bottom: 2.0),
          child: Text(
            item.label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
