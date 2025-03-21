import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/layout/context_menu.dart';
import 'package:jouhakka_forge/3_components/layout/context_popup.dart';
import 'package:jouhakka_forge/3_components/layout/my_tooltip.dart';
import 'package:jouhakka_forge/5_style/colors.dart';
import 'package:jouhakka_forge/5_style/textstyles.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class InspectorTitle extends StatefulWidget {
  final String title;
  final bool big;
  final bool canShrink;
  final bool initialShrink;
  final String? tip;
  final List<ContextMenuItem> contextMenuItems;
  final Function(bool shrink)? onShrink;
  final bool divider;
  const InspectorTitle(
    this.title, {
    super.key,
    this.canShrink = true,
    this.initialShrink = false,
    this.tip,
    this.contextMenuItems = const [],
    this.onShrink,
    this.divider = false,
    this.big = false,
  });

  @override
  State<InspectorTitle> createState() => _InspectorTitleState();
}

class _InspectorTitleState extends State<InspectorTitle> {
  bool shrinked = false;
  MyIconButtonDecoration get decoration => widget.big
      ? const MyIconButtonDecoration(
          size: 18,
          iconColor: InteractiveColorSettings(color: MyColors.slate),
        )
      : const MyIconButtonDecoration(
          size: 16,
          iconColor: InteractiveColorSettings(color: MyColors.slate),
        );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.canShrink)
          MyIconButton(
            icon: shrinked ? LucideIcons.chevronRight : LucideIcons.chevronDown,
            decoration: decoration,
            primaryAction: (_) {
              setState(
                () {
                  shrinked = !shrinked;
                },
              );
              widget.onShrink?.call(shrinked);
            },
          ),
        Text(
          widget.title,
          style: widget.canShrink
              ? widget.big
                  ? MyTextStyles.header1
                  : MyTextStyles.header2
              : widget.big
                  ? MyTextStyles.darkTitle
                  : MyTextStyles.darkHeader3,
        ),
        const Spacer(),
        ..._tipOrMenu(),
      ],
    );
  }

  List<Widget> _tipOrMenu() {
    if (widget.contextMenuItems.isNotEmpty) {
      List<ContextMenuItem> items = widget.contextMenuItems;
      if (widget.tip != null) {
        items.add(
          ContextMenuItem(
            "Help",
            action: (details) {
              ContextPopup.open(context,
                  clickPosition: details.globalPosition,
                  child: Text(widget.tip!));
            },
          ),
        );
      }
      return [
        MyIconButton(
          icon: LucideIcons.ellipsis,
          decoration: decoration,
          primaryAction: (details) {
            ContextMenu.open(context, details.globalPosition, items);
          },
        ),
      ];
    } else {
      return [
        if (widget.tip != null)
          /*MyIconButton(
            icon: LucideIcons.circleHelp,
            decoration: decoration,
            primaryAction: (details) {
              ContextPopup.open(
                context,
                clickPosition: details.globalPosition,
                child: Text(widget.tip!),
              );
            },
          ),*/
          MyTooltip(
            widget.tip ?? "",
            child: Icon(
              LucideIcons.circleHelp,
              color: MyColors.slate,
              size: decoration.size,
            ),
          ),
      ];
    }
  }
}
