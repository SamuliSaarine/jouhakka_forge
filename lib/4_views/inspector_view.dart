import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/element/inspector_modules/a_inspector_modules.dart';
import 'package:jouhakka_forge/3_components/element/inspector_modules/branch_inspector_modules.dart';
import 'package:jouhakka_forge/3_components/element/inspector_modules/leaf_inspector_modules.dart';
import 'package:jouhakka_forge/3_components/layout/context_menu.dart';
import 'package:jouhakka_forge/3_components/layout/inspector_boxes.dart';
import 'package:jouhakka_forge/3_components/layout/inspector_title.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

class InspectorView extends StatelessWidget {
  final ElementRoot root;
  const InspectorView(this.root, {super.key});

  //TODO: Make decoration editable
  //TODO: Implement editor for image elements
  //TODO: Make padding editable
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: MyColors.light,
      child: SingleChildScrollView(
        child: ValueListener(
          source: Session.selectedElement,
          builder: (element) {
            if (element == null) {
              return _rootInspector(context);
            } else {
              return _elementInspector(element, context);
            }
          },
        ),
      ),
    );
  }

  Widget _inspectorBuilder(
    BuildContext context,
    String title, {
    String tip = "",
    List<ContextMenuItem> contextMenuChoices = const [],
    required List<Widget> children,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 6.0, right: 6.0, top: 4.0, bottom: 2.0),
          child: InspectorTitle(
            title,
            canShrink: false,
            big: true,
            tip: tip,
            contextMenuItems: contextMenuChoices,
          ),
        ),
        MyDividers.strongHorizontal,
        for (var child in children) ...[
          child,
          MyDividers.strongHorizontal,
        ],
      ],
    );
  }

  Widget _elementInspector(UIElement element, BuildContext context) {
    return _inspectorBuilder(
      context,
      element.label,
      tip: element.id,
      contextMenuChoices: [
        ContextMenuItem(
          "Delete",
          action: (details) {
            if (element.parent == null) {
              debugPrint("Cannot delete element without parent");
              return;
            }
            element.parent!.removeChild(element);
          },
        ),
      ],
      children: [
        element.size.getEditor(element),
        if (element is LeafElement) _leafElementInspector(element),
        if (element is BranchElement) _branchElementInspector(element, context),
      ],
    );
  }

  Widget _rootInspector(BuildContext context) {
    return _inspectorBuilder(
      context,
      root.title,
      contextMenuChoices: [
        ContextMenuItem(
          "Delete",
          action: (details) {
            root.folder.removeItem(Session.lastPage.value!);
            if (root == Session.lastPage.value) {
              Session.lastPage.value = null;
            } else if (root == Session.lastComponent.value) {
              Session.lastComponent.value = null;
            }
          },
        ),
      ],
      children: [
        root.variables.getEditor(root),
        Session.currentProject.value!.variables.getEditor(null),
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

  Widget _branchElementInspector(BranchElement element, BuildContext context) {
    return ManyChangeListeners(
      sources: [
        element.content.hasValueNotifier,
        element.decoration.hasValueNotifier
      ],
      builder: () {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (element.content.value != null)
              element.content.value!.getEditor(),
            if (element.decoration.value != null)
              element.decoration.value!.getEditor(
                context,
                element,
                onDelete: () => element.decoration.value = null,
              ),
            AddPropertiesEditor(properties: [
              if (element.decoration.value == null)
                (
                  "Decoration",
                  Icons.format_paint,
                  () {
                    element.decoration.value = ElementDecoration();
                  }
                ),
            ])
          ],
        );
      },
    );
  }
}
