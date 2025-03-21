import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/layout/context_menu.dart';
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/layout/inspector_title.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

class HeadPropertyBox extends StatefulWidget {
  final String title;
  final String tip;
  final List<ContextMenuItem> contextMenuItems;
  final List<Widget> children;
  const HeadPropertyBox({
    super.key,
    required this.children,
    required this.title,
    required this.tip,
    required this.contextMenuItems,
  });

  @override
  State<HeadPropertyBox> createState() => _HeadPropertyBoxState();
}

class _HeadPropertyBoxState extends State<HeadPropertyBox> {
  bool shrinked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InspectorTitle(
                widget.title,
                tip: widget.tip,
                big: true,
                contextMenuItems: widget.contextMenuItems,
                onShrink: (shrinked) {
                  setState(() {
                    this.shrinked = shrinked;
                  });
                },
              ),
              if (!shrinked) ..._buildChildren(widget.children)
            ],
          ),
        ),
        MyDividers.strongHorizontal,
      ],
    );
  }
}

class SubPropertyBox extends StatefulWidget {
  final String title;
  final String tip;
  final List<ContextMenuItem> contextMenuItems;
  final List<Widget> children;
  final Widget? sideChild;
  const SubPropertyBox({
    super.key,
    required this.children,
    required this.title,
    required this.tip,
    required this.contextMenuItems,
    this.sideChild,
  });

  @override
  State<SubPropertyBox> createState() => _SubPropertyBoxState();
}

class _SubPropertyBoxState extends State<SubPropertyBox> {
  bool shrinked = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorTitle(
          widget.title,
          tip: widget.tip,
          contextMenuItems: widget.contextMenuItems,
          onShrink: (shrinked) {
            setState(() {
              this.shrinked = shrinked;
            });
          },
        ),
        if (!shrinked)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.sideChild == null)
                  ..._buildChildren(widget.children)
                else if (widget.sideChild != null)
                  Row(
                    children: [
                      widget.sideChild!,
                      Gap.w2,
                      const ColoredBox(
                        color: MyColors.storm,
                        child: SizedBox(
                          width: 1,
                        ),
                      ),
                      Gap.w2,
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildChildren(widget.children),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          )
      ],
    );
  }
}

List<Widget> _buildChildren(List<Widget> children) {
  return [
    for (var child in children) ...[
      Gap.h6,
      const ColoredBox(
        color: MyColors.storm30,
        child: SizedBox(
          height: 1,
        ),
      ),
      Gap.h6,
      child,
    ]
  ];
}

class MyDividers {
  MyDividers._();

  static ColoredBox lightVertical = const ColoredBox(
    color: MyColors.storm30,
    child: SizedBox(
      width: 1,
    ),
  );

  static ColoredBox strongVertical = const ColoredBox(
    color: MyColors.slate,
    child: SizedBox(
      width: 1,
    ),
  );

  static ColoredBox lightHorizontal = const ColoredBox(
    color: MyColors.storm30,
    child: SizedBox(
      height: 1,
    ),
  );

  static ColoredBox strongHorizontal = const ColoredBox(
    color: MyColors.slate,
    child: SizedBox(
      height: 1,
    ),
  );
}

class PropertyFieldBox extends StatelessWidget {
  final String title;
  final String tip;
  final List<ContextMenuItem> contextMenuItems;
  final Widget content;
  const PropertyFieldBox({
    super.key,
    required this.title,
    required this.tip,
    required this.contextMenuItems,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectorTitle(
            title,
            tip: tip,
            contextMenuItems: contextMenuItems,
            canShrink: false,
          ),
          Gap.h2,
          content,
        ],
      ),
    );
  }
}
