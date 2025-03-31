import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/layout/context_menu.dart';
import 'package:jouhakka_forge/3_components/layout/element_selector_list.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(widget.rootFolder.name),
                const Spacer(),
                MyIconButton(
                  icon: Icons.note_add_outlined,
                  primaryAction: (_) {
                    widget.rootFolder.newItem();
                    setState(() {});
                  },
                ),
                MyIconButton(
                  icon: Icons.create_new_folder_outlined,
                  primaryAction: (_) {
                    widget.rootFolder.addNewFolder("New Folder");
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const Divider(
            indent: 0,
            endIndent: 0,
            thickness: 1,
            height: 1,
          ),
          Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: ValueListener(
                source: T == UIPage ? Session.lastPage : Session.lastComponent,
                builder: (lastRoot) {
                  return RootSelectorList<T>(
                    widget.rootFolder,
                    selectedRoot: lastRoot as T?,
                    onSelection: widget.onSelection,
                  );
                },
              ),
            ),
          ),
          const Divider(),
          Flexible(
            flex: 2,
            child: ValueListener(
              source: T == UIPage ? Session.lastPage : Session.lastComponent,
              builder: (lastRoot) {
                if (lastRoot == null) {
                  return Text(T == UIPage
                      ? "No page selected"
                      : "No component selected");
                }
                return Column(
                  children: [
                    Text(
                      "Selected: ${lastRoot.title}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    SingleChildScrollView(
                      child: ChangeListener(
                        source: lastRoot,
                        builder: () {
                          return ElementSelectorList(
                            null,
                            root: lastRoot,
                            onSelection: (element) {
                              Session.selectedElement.value = element;
                            },
                            initiallyExpanded: true,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RootSelectorList<T extends ElementRoot> extends StatefulWidget {
  final ElementRootFolder<T> folder;
  final T? selectedRoot;
  final void Function(T item) onSelection;

  const RootSelectorList(this.folder,
      {super.key, required this.onSelection, this.selectedRoot});

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
    if (subfolder.isExpanded &&
        (subfolder.folders.isNotEmpty || subfolder.items.isNotEmpty)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _folderItemWidget(subfolder, index),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
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
      primaryActionDown: (_) {
        setState(() {
          folder.isExpanded = !folder.isExpanded;
        });
      },
      secondaryActionUp: (details) {
        bool isPage = T == UIPage;
        ContextMenu.open(
          context,
          details.globalPosition,
          [
            ContextMenuItem(
              "New ${isPage ? "page" : "component"}",
              action: (_) {
                folder.newItem();
                setState(() {});
              },
            ),
            ContextMenuItem(
              "New folder",
              action: (_) {
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
              Icon(
                folder.isExpanded
                    ? LucideIcons.chevronDown
                    : Icons.chevron_right,
                size: 12,
              ),
              Text(folder.name, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemWidget(T item, int index) {
    return ClickDetector(
      primaryActionDown: (_) {
        widget.onSelection(item);
      },
      builder: (hovering, _) => ColoredBox(
        color: (hovering || item == widget.selectedRoot)
            ? Colors.grey[200]!
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(item.title),
        ),
      ),
    );
  }
}
