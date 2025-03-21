import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/layout/context_popup.dart';

class ContextMenu extends StatefulWidget {
  final List<ContextMenuItem> items;
  const ContextMenu(this.items, {super.key});

  static void open(
      BuildContext context, Offset position, List<ContextMenuItem> items) {
    ContextPopup.open(
      context,
      clickPosition: position,
      child: ContextMenu(items),
    );
  }

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  int hovering = -1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            for (int i = 0; i < widget.items.length; i++)
              _buildItem(widget.items[i], i),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(ContextMenuItem item, int index) {
    bool enabled = true;
    if (item.condition != null) {
      enabled = item.condition!();
    }
    return ClickDetector(
      primaryActionDown: enabled
          ? (details) {
              ContextPopup.close();
              item.action(details);
            }
          : null,
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
      opaque: true,
      child: ColoredBox(
        color: hovering == index ? Colors.grey[200]! : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Text(
                item.text,
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? Colors.black : Colors.grey,
                ),
              ),
              if (item.shortcut != null) ...[
                const Spacer(),
                Text(item.shortcut!.toString()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ContextMenuItem {
  final String text;
  final ShortcutActivator? shortcut;
  final bool Function()? condition;
  final Function(TapDownDetails tapDetails) action;

  const ContextMenuItem(
    this.text, {
    this.shortcut,
    this.condition,
    required this.action,
  });
}
