import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';
import 'package:jouhakka_forge/4_views/inspector_modules.dart';

class InspectorView extends StatelessWidget {
  final ElementRoot root;
  const InspectorView(this.root, {super.key});

  //TODO: Make decoration editable
  //TODO: Implement editor for image elements
  //TODO: Make padding editable
  @override
  Widget build(BuildContext context) {
    bool isPage = root is Page;
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(-1, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: ValueListener(
          source: Session.selectedElement,
          builder: (element) {
            if (element == null) {
              return _rootInspector(isPage);
            } else {
              return _elementInspector(element);
            }
          },
        ),
      ),
    );
  }

  Widget _elementInspector(UIElement element) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(element.id),
        Text(element.label),
        const Divider(),
        if (element.parent != null) ...[
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: element.width.getEditor("Width")),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: element.height.getEditor("Height"),
          ),
        ],
        if (element.parent == null)
          const Center(
            child: Text("Cannot edit size of root element"),
          ),
        const Divider(),
        const Divider(),
        if (element is ElementContainer) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: element.type.getEditor(onScrollEnable: (axis) {
              for (UIElement child in element.children) {
                if (axis == Axis.horizontal &&
                    child.width.type == SizeType.expand) {
                  child.width.type = SizeType.fixed;
                } else if (axis == Axis.vertical &&
                    child.height.type == SizeType.expand) {
                  child.height.type = SizeType.fixed;
                }
              }
            }),
          ),
          const Divider(),
        ],
      ],
    );
  }

  Widget _rootInspector(bool isPage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(isPage ? "Page" : "Component"),
      ],
    );
  }

  Widget _leafElementInspector(LeafElement element) {
    final Widget? editor;
    if (element is ImageElement) {
      //TODO: Implement editor for image elements
      editor = null;
    } else if (element is IconElement) {
      editor = element.getEditor();
    } else if (element is TextElement) {
      editor = element.getEditor();
    } else {
      debugPrint("No editor found for element: ${element.label}");
      editor = null;
    }

    return Padding(padding: const EdgeInsets.all(16), child: editor);
  }

  Widget _branchElementInspector(BranchElement element) {
    return Column(
      children: [
        element.decoration.getEditor(),
        if (element.content.value != null) ...[
          element.content.value!.getEditor(),
        ],
      ],
    );
  }
}
