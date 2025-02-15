import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/text_field.dart';
import 'package:jouhakka_forge/5_style/colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

extension EVEditor<T> on EV<T> {}

extension AxisSizeEditor on AxisSize {
  Widget getEditor(String title) {
    final TextEditingController valueController =
        TextEditingController(text: value != null ? value!.toString() : "");
    final TextEditingController minController = TextEditingController(
        text: minPixels != null ? minPixels!.toString() : "");
    final TextEditingController maxController = TextEditingController(
        text: maxPixels != null ? maxPixels!.toString() : "");
    final TextEditingController flexController =
        TextEditingController(text: flex != null ? flex!.toString() : "");

    return ChangeListener(
      source: this,
      builder: () {
        debugPrint("Building AxisSizeEditor for $title: $value");
        if (valueController.text != value.toString()) {
          valueController.text = value.toString();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$title:",
                style: const TextStyle(
                    fontSize: 12,
                    color: MyColors.lighterCharcoal,
                    fontWeight: FontWeight.w700)),
            Gap.h2,
            Row(
              children: [
                Expanded(
                  child: MyNumberField<double>(
                      controller: valueController,
                      hintText: "$title in pixels",
                      onChanged: (value) => fixed(value)),
                ),
                Gap.w8,
                //MyIconButtons for auto, expand, fixed
                FloatingBar(
                  decoration: FloatingBarDecoration.flatLightMode,
                  children: [
                    MyIconButton(
                        icon: LucideIcons.shrink,
                        tooltip: "Auto",
                        size: 14,
                        isSelected: type == SizeType.auto,
                        decoration: MyIconButtonDecoration.onDarkBar,
                        primaryAction: (_) {
                          auto();
                        }),
                    MyIconButton(
                        icon: LucideIcons.expand,
                        tooltip: "Expand",
                        size: 14,
                        isSelected: type == SizeType.expand,
                        decoration: MyIconButtonDecoration.onDarkBar,
                        primaryAction: (_) {
                          expand();
                        }),
                    MyIconButton(
                      icon: LucideIcons.ruler,
                      tooltip: "Fixed",
                      size: 14,
                      isSelected: type == SizeType.fixed,
                      decoration: MyIconButtonDecoration.onDarkBar,
                      primaryAction: (_) {
                        if (value != null) {
                          fixed(value!);
                        } else {
                          debugPrint("Value is null");
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            //Min, max and if expand, flex
            if (type != SizeType.fixed) ...[
              Gap.h8,
              Row(
                children: [
                  Expanded(
                    child: MyNumberField<double>(
                      controller: minController,
                      hintText: "Min",
                      onChanged: (value) {
                        minPixels = value;
                      },
                    ),
                  ),
                  Gap.w4,
                  Expanded(
                    child: MyNumberField<double>(
                      controller: maxController,
                      hintText: "Max",
                      onChanged: (value) {
                        maxPixels = value;
                      },
                    ),
                  ),
                  if (type == SizeType.expand) ...[
                    Gap.w4,
                    Expanded(
                      child: MyNumberField<int>(
                        controller: flexController,
                        hintText: "Flex",
                        onChanged: (value) {
                          flex = value;
                        },
                      ),
                    ),
                  ]
                ],
              ),
            ]
          ],
        );
      },
    );
  }
}

extension ContainerElementEditor on ContainerElementType {
  Widget getEditor({required void Function(Axis axis) onScrollEnable}) {
    return ChangeListener(
        source: this,
        builder: () {
          return Column(
            children: [
              _scrollChoice(onScrollEnable),
              _fromType(),
            ],
          );
        });
  }

  Widget _fromType() {
    if (this is SingleChildElementType) {
      return _singleChildEditor(this as SingleChildElementType);
    } else if (this is FlexElementType) {
      return _flexEditor(this as FlexElementType);
    } else {
      return const Text("Unsupported container type");
    }
  }

  Widget _scrollChoice(void Function(Axis axis) onScrollEnable) {
    return FloatingBar(children: [
      MyIconButton(
        icon: LucideIcons.lock,
        tooltip: "No scroll",
        size: 14,
        decoration: MyIconButtonDecoration.onDarkBar,
        isSelected: scroll == null,
        primaryAction: (_) {
          scroll = null;
        },
      ),
      MyIconButton(
        icon: LucideIcons.moveVertical,
        tooltip: "Vertical scroll",
        size: 14,
        decoration: MyIconButtonDecoration.onDarkBar,
        isSelected: scroll == Axis.vertical,
        primaryAction: (_) {
          onScrollEnable(Axis.vertical);
          scroll = Axis.vertical;
        },
      ),
      MyIconButton(
        icon: LucideIcons.moveHorizontal,
        tooltip: "Horizontal scroll",
        size: 14,
        decoration: MyIconButtonDecoration.onDarkBar,
        isSelected: scroll == Axis.horizontal,
        primaryAction: (_) {
          onScrollEnable(Axis.horizontal);
          scroll = Axis.horizontal;
        },
      ),
    ]);
  }

  Widget _singleChildEditor(SingleChildElementType type) {
    Widget alignmentButton(Alignment alignment) {
      return MyIconButton(
        icon: Icons.circle,
        size: 14,
        decoration: const MyIconButtonDecoration(
          iconColor: InteractiveColorSettings(
              color: MyColors.lighterCharcoal,
              selectedColor: MyColors.mint,
              hoverColor: MyColors.lightMint),
        ),
        isSelected: alignment == type.alignment,
        primaryAction: (_) {
          type.alignment = alignment;
        },
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: MyColors.darkerCharcoal,
        border: Border.all(color: MyColors.lighterCharcoal),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            children: [
              alignmentButton(Alignment.topLeft),
              alignmentButton(Alignment.centerLeft),
              alignmentButton(Alignment.bottomLeft),
            ],
          ),
          Column(
            children: [
              alignmentButton(Alignment.topCenter),
              alignmentButton(Alignment.center),
              alignmentButton(Alignment.bottomCenter),
            ],
          ),
          Column(
            children: [
              alignmentButton(Alignment.topRight),
              alignmentButton(Alignment.centerRight),
              alignmentButton(Alignment.bottomRight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flexEditor(FlexElementType type) {
    bool isVertical = type.direction == Axis.vertical;
    return Column(
      children: [
        FloatingBar(
          children: [
            MyIconButton(
              icon: LucideIcons.arrowDown,
              size: 14,
              decoration: MyIconButtonDecoration.onDarkBar,
              isSelected: type.direction == Axis.vertical,
              primaryAction: (_) {
                type.direction = Axis.vertical;
              },
            ),
            MyIconButton(
              icon: LucideIcons.arrowRight,
              size: 14,
              decoration: MyIconButtonDecoration.onDarkBar,
              isSelected: type.direction == Axis.horizontal,
              primaryAction: (_) {
                type.direction = Axis.horizontal;
              },
            ),
          ],
        ),
        Column(
          children: [
            //Main axis alignment
            FloatingBar(
              children: [
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignStartVertical
                      : LucideIcons.alignStartHorizontal,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar,
                  isSelected: type.mainAxisAlignment == MainAxisAlignment.start,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.start;
                  },
                ),
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignEndVertical
                      : LucideIcons.alignEndHorizontal,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar,
                  isSelected: type.mainAxisAlignment == MainAxisAlignment.end,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.end;
                  },
                ),
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignCenterVertical
                      : LucideIcons.alignCenterHorizontal,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar,
                  isSelected:
                      type.mainAxisAlignment == MainAxisAlignment.center,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.center;
                  },
                ),
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignVerticalSpaceAround
                      : LucideIcons.alignHorizontalSpaceAround,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar,
                  isSelected:
                      type.mainAxisAlignment == MainAxisAlignment.spaceAround,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.spaceAround;
                  },
                ),
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignVerticalSpaceBetween
                      : LucideIcons.alignHorizontalSpaceBetween,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar,
                  isSelected:
                      type.mainAxisAlignment == MainAxisAlignment.spaceBetween,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.spaceBetween;
                  },
                ),
              ],
            ),
            //Cross axis alignment
            FloatingBar(children: [
              MyIconButton(
                icon: isVertical
                    ? LucideIcons.alignStartHorizontal
                    : LucideIcons.alignStartVertical,
                size: 14,
                decoration: MyIconButtonDecoration.onDarkBar,
                isSelected: type.crossAxisAlignment == CrossAxisAlignment.start,
                primaryAction: (_) {
                  type.crossAxisAlignment = CrossAxisAlignment.start;
                },
              ),
              MyIconButton(
                icon: isVertical
                    ? LucideIcons.alignEndHorizontal
                    : LucideIcons.alignEndVertical,
                size: 14,
                decoration: MyIconButtonDecoration.onDarkBar,
                isSelected: type.crossAxisAlignment == CrossAxisAlignment.end,
                primaryAction: (_) {
                  type.crossAxisAlignment = CrossAxisAlignment.end;
                },
              ),
              MyIconButton(
                icon: isVertical
                    ? LucideIcons.alignCenterHorizontal
                    : LucideIcons.alignCenterVertical,
                size: 14,
                decoration: MyIconButtonDecoration.onDarkBar,
                isSelected:
                    type.crossAxisAlignment == CrossAxisAlignment.center,
                primaryAction: (_) {
                  type.crossAxisAlignment = CrossAxisAlignment.center;
                },
              ),
              MyIconButton(
                icon: isVertical
                    ? LucideIcons.stretchHorizontal
                    : LucideIcons.stretchVertical,
                size: 14,
                decoration: MyIconButtonDecoration.onDarkBar,
                isSelected:
                    type.crossAxisAlignment == CrossAxisAlignment.stretch,
                primaryAction: (_) {
                  type.crossAxisAlignment = CrossAxisAlignment.stretch;
                },
              ),
              if (!isVertical)
                MyIconButton(
                  icon: LucideIcons.baseline,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar,
                  isSelected:
                      type.crossAxisAlignment == CrossAxisAlignment.baseline,
                  primaryAction: (_) {
                    type.crossAxisAlignment = CrossAxisAlignment.baseline;
                  },
                ),
            ]),
          ],
        ),
      ],
    );
  }
}

extension TextElementEditor on TextElement {
  Widget getEditor() {
    final TextEditingController textController =
        TextEditingController(text: text);
    final TextEditingController fontSizeController =
        TextEditingController(text: fontSize.toString());

    return ChangeListener(
      source: this,
      builder: () {
        return Column(
          children: [
            MyTextField(
              controller: textController,
              hintText: "Text",
              onChanged: (value) {
                text = value;
              },
            ),
            Gap.h8,
            MyNumberField<double>(
              controller: fontSizeController,
              hintText: "Font size",
              onChanged: (value) {
                fontSize = value;
              },
            ),
          ],
        );
      },
    );
  }
}

extension IconElementEditor on IconElement {
  Widget getEditor() {
    final List<IconData> icons = [
      LucideIcons.star,
      LucideIcons.heart,
      LucideIcons.plus,
      LucideIcons.play,
      LucideIcons.camera,
      LucideIcons.chevronDown,
      LucideIcons.chevronRight,
      LucideIcons.search,
      LucideIcons.house,
      LucideIcons.send,
      LucideIcons.messageCircle,
      LucideIcons.ellipsis,
      LucideIcons.ellipsisVertical,
    ];

    return ChangeListener(
      source: this,
      builder: () {
        return Wrap(
          spacing: 8.0,
          children: [
            for (IconData iconData in icons)
              MyIconButton(
                icon: iconData,
                size: 24,
                decoration: const MyIconButtonDecoration(
                  iconColor: InteractiveColorSettings(color: Colors.black),
                  backgroundColor: InteractiveColorSettings(
                    color: Colors.white,
                    hoverColor: Color.fromARGB(255, 210, 210, 210),
                    selectedColor: Color.fromARGB(255, 107, 107, 107),
                  ),
                  borderRadius: 12,
                ),
                isSelected: icon == iconData,
                primaryAction: (_) {
                  icon = iconData;
                },
              ),
          ],
        );
      },
    );
  }
}
