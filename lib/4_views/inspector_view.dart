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
    bool isPage = root is Page;
    return Container(
      width: 280,
      color: MyColors.light,
      child: SingleChildScrollView(
        child: ValueListener(
          source: Session.selectedElement,
          builder: (element) {
            if (element == null) {
              return _rootInspector(isPage);
            } else {
              return _elementInspector(element, context);
            }
          },
        ),
      ),
    );
  }

  Widget _elementInspector(UIElement element, BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 6.0, right: 6.0, top: 4.0, bottom: 2.0),
          child: InspectorTitle(
            element.label,
            canShrink: false,
            big: true,
            tip: element.id,
            contextMenuItems: [
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
          ),
        ),
        MyDividers.strongHorizontal,
        element.size.getEditor(element),
        //_sizeEditors(element),
        MyDividers.strongHorizontal,
        if (element is LeafElement) _leafElementInspector(element),
        if (element is BranchElement) _branchElementInspector(element, context),
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
          ],
        );
      },
    );
  }

  /*Widget _sizeEditors(UIElement element) {
    if (element.parent != null) {
      return Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(children: [
          PropertyFieldBox(
              title: "Width",
              tip: "Width of element",
              content: element.size.width.getEditor("Width"),
              contextMenuItems: const []),
          Gap.h2,
          MyDividers.lightHorizontal,
          Gap.h2,
          PropertyFieldBox(
              title: "Height",
              tip: "Height of element",
              content: element.size.height.getEditor("Height"),
              contextMenuItems: const []),
        ]),
      );
    } else {
      return const Center(
        child: Text("Cannot edit size of root element"),
      );
    }
  }*/
}
