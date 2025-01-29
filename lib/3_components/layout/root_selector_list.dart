import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/component.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/layout/context_menu.dart';

class RootSelectorPanel<T extends ElementRoot> extends StatefulWidget {
  final ElementRootFolder<T> rootFolder;
  final void Function(T item) onSelection;

  const RootSelectorPanel(this.rootFolder,
      {super.key, required this.onSelection});

  @override
  State<RootSelectorPanel> createState() => _RootSelectorPanelState<T>();
}

class _RootSelectorPanelState<T extends ElementRoot>
    extends State<RootSelectorPanel<T>> {
  @override
  void initState() {
    super.initState();
    debugPrint("RootSelectorPanel<$T> created for ${widget.rootFolder.name}");
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(widget.rootFolder.name),
                const Spacer(),
                MyIconButton(
                  icon: Icons.note_add_outlined,
                  primaryAction: (_) {
                    T newItem = T == UIPage
                        ? UIPage.empty() as T
                        : UIComponent.empty() as T;

                    widget.rootFolder.addNewItem(newItem);
                    setState(() {});
                  },
                ),
                MyIconButton(
                    icon: Icons.create_new_folder_outlined,
                    primaryAction: (_) {
                      widget.rootFolder.addNewFolder("New Folder");
                      setState(() {});
                    }),
              ],
            ),
          ),
          const Divider(indent: 0, endIndent: 0),
          Expanded(
            child: SingleChildScrollView(
              child: RootSelectorList<T>(
                widget.rootFolder,
                onSelection: widget.onSelection,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RootSelectorList<T extends ElementRoot> extends StatefulWidget {
  final ElementRootFolder<T> folder;
  final void Function(T item) onSelection;

  const RootSelectorList(this.folder, {super.key, required this.onSelection});

  @override
  State<RootSelectorList> createState() => _RootSelectorListState<T>();
}

class _RootSelectorListState<T extends ElementRoot>
    extends State<RootSelectorList<T>> {
  int hovering = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int foldersPlusItems =
        widget.folder.folders.length + widget.folder.items.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int index = 0; index < foldersPlusItems; index++)
          _resolveWidget(index),
      ],
    );
  }

  Widget _resolveWidget(int index) {
    if (index < widget.folder.folders.length) {
      ElementRootFolder<T> subfolder = widget.folder.folders[index];
      return _subfolderWidget(subfolder, index);
    }
    T item = widget.folder.items[index - widget.folder.folders.length];
    return _itemWidget(item, index);
  }

  Widget _subfolderWidget(ElementRootFolder<T> subfolder, int index) {
    if (subfolder.isExpanded && subfolder.totalItems > 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _folderItemWidget(subfolder, index),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: RootSelectorList<T>(subfolder,
                onSelection: (root) => widget.onSelection(root)),
          ),
        ],
      );
    } else {
      return _folderItemWidget(subfolder, index);
    }
  }

  Widget _folderItemWidget(ElementRootFolder<T> folder, int index) {
    return ClickDetector(
      primaryAction: () {
        setState(() {
          folder.isExpanded = !folder.isExpanded;
        });
      },
      secondaryActionWithDetails: (details) {
        bool isPage = T == UIPage;
        ContextMenu.open(
          context,
          details.globalPosition,
          [
            ContextMenuItem(
              "New ${isPage ? "page" : "component"}",
              action: () {
                T newItem =
                    isPage ? UIPage.empty() as T : UIComponent.empty() as T;

                folder.addNewItem(newItem);
                setState(() {});
              },
            ),
            ContextMenuItem(
              "New folder",
              action: () {
                folder.addNewFolder("New Folder");
                setState(() {});
              },
            ),
          ],
        );
      },
      onPointerEvent: (event) {
        if (event is PointerExitEvent) {
          if (hovering != index) return;
          setState(() {
            hovering = -1;
          });
        } else if (index != hovering) {
          setState(() {
            hovering = index;
          });
        }
      },
      child: ColoredBox(
        color: hovering == index ? Colors.grey[200]! : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(folder.isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right),
              Text(folder.name),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemWidget(T item, int index) {
    return ClickDetector(
      primaryAction: () {
        widget.onSelection(item);
      },
      onPointerEvent: (event) {
        if (event is PointerExitEvent) {
          if (hovering != index) return;
          setState(() {
            hovering = -1;
          });
        } else if (index != hovering) {
          setState(() {
            hovering = index;
          });
        }
      },
      child: ColoredBox(
        color: hovering == index ? Colors.grey[200]! : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(item.title),
        ),
      ),
    );
  }
}
